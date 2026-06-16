using Microsoft.Extensions.Logging;
using WpfDevPackMcp.Configuration;
using WpfDevPackMcp.Git;

namespace WpfDevPackMcp.Knowledge;

public sealed class RepoNotConfiguredException()
    : Exception(
        "WPF knowledge repo path is not configured. This requires a one-time USER setup — " +
        "do NOT auto-detect the repo or run set-repo-path yourself; ask the user to run " +
        "/wpf-net472-airgap-dev-pack:set-repo-path <path>.");

/// <summary>
/// Facade the MCP tools depend on: resolves the repo, refreshes (TTL/forced),
/// and exposes catalog operations. Throws RepoNotConfiguredException when no
/// path is set (the RepoPathGuard hook normally prevents reaching here).
/// </summary>
public sealed class KnowledgeService(ConfigStore store, GitRunner git, ILogger<KnowledgeService> logger)
{
    private static readonly TimeSpan Ttl = ReadTtl();
    private static readonly bool Offline = ReadOffline();
    private readonly Lock _gate = new();
    private TopicCatalog? _catalog;
    private string? _catalogRoot;

    public void EnsureReady(bool force = false)
    {
        var repo = store.Resolve() ?? throw new RepoNotConfiguredException();

        // Air-gapped fork: serve the local clone as-is. No clone/fetch/pull is
        // performed unless network refresh is explicitly opted in via
        // WPFDEVPACK_OFFLINE=0. This guarantees the server never touches the
        // network during normal closed-network operation.
        if (!Offline)
        {
            var state = RepoRefresher.EnsureFresh(repo, store.LoadState(), Ttl, force, git, store, logger);
            _ = state;
        }

        lock (_gate)
        {
            if (_catalog is null || !string.Equals(_catalogRoot, repo.Path, StringComparison.Ordinal))
            {
                _catalog = new TopicCatalog(repo.Path);
                _catalogRoot = repo.Path;
            }
            else if (force)
            {
                _catalog.Invalidate();
            }
        }
    }

    public TopicCatalog Catalog
    {
        get
        {
            lock (_gate)
            {
                return _catalog ?? throw new RepoNotConfiguredException();
            }
        }
    }

    private static TimeSpan ReadTtl()
    {
        var raw = Environment.GetEnvironmentVariable("WPFDEVPACK_PULL_TTL_MINUTES");
        return int.TryParse(raw, out var m) && m >= 0 ? TimeSpan.FromMinutes(m) : TimeSpan.FromMinutes(60);
    }

    // Offline by default (air-gapped fork). Only an explicit opt-out re-enables
    // network refresh: WPFDEVPACK_OFFLINE=0 (also accepts "false"/"no").
    private static bool ReadOffline()
    {
        var raw = Environment.GetEnvironmentVariable("WPFDEVPACK_OFFLINE");
        if (string.IsNullOrWhiteSpace(raw))
            return true;
        return raw.Trim() is not ("0" or "false" or "False" or "FALSE" or "no" or "No");
    }
}
