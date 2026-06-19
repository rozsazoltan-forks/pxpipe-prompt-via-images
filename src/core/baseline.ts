/**
 * Cache-aware baseline math for the unproxied counterfactual.
 * Workers-safe: no node:, no Buffer, no process.*. Pure number math.
 * See docs/CACHING_AND_SAVINGS.md for the full derivation and audit history.
 */

/** Documented Anthropic price ratios: cc_5m = 1.25×, cr = 0.1× base input. One-line change if rates change. */
export const CACHE_CREATE_RATE = 1.25;
export const CACHE_READ_RATE = 0.1;

/**
 * Weighted input cost for the unproxied TEXT counterfactual (see docs/CACHING_AND_SAVINGS.md).
 *
 * Warmth matters: a TEXT prefix is only a cheap cache-read when a warm cache
 * actually existed this turn. The previous warmth-FREE version always priced
 * the cacheable prefix at CACHE_READ_RATE, which fabricated a "free read" on
 * cold/TTL-expiry turns where text would in fact have paid a 1.25× create —
 * that produced a phantom loss vs the imaged path (which DOES pay the create).
 *
 *   cold turn (first turn / >5min since this session's last turn):
 *     text has no warm cache either ⇒ cacheable×CACHE_CREATE_RATE + coldTail×1.0
 *   warm turn (a prior turn cached the prefix within TTL):
 *     text append-caches ⇒ reused×CACHE_READ_RATE + grown×CACHE_CREATE_RATE + coldTail×1.0
 *     where reused = min(prevCacheable, cacheable), grown = cacheable − reused.
 *     This is what TEXT pays regardless of whether pxpipe's image busted its
 *     own cache on a growth turn — so the real growth loss is preserved.
 *
 * Saving = baseline_eff − actual_eff; can be negative (honestly reported, not floored).
 *
 * @param baselineCacheable  tokens up to the last cache_control marker. ≤0 ⇒ credit nothing.
 * @param warm               was a warm cache available for this session this turn?
 * @param prevCacheable      cacheable prefix size on this session's previous turn (warm only).
 */
export function computeBaselineInputEff(
  baseline: number,
  baselineCacheable: number,
  inputTokens: number,
  cc: number,
  cr: number,
  warm = false,
  prevCacheable = 0,
): number {
  if (baseline <= 0) return 0;
  // Probe miss: can't split prefix from tail, so credit nothing (same as actual).
  if (baselineCacheable <= 0) return computeActualInputEff(inputTokens, cc, cr);
  const cacheable = Math.min(baselineCacheable, baseline);
  const coldTail = baseline - cacheable;
  if (warm) {
    // Text reads the prefix it already had cached (0.10×) and creates only the
    // growth since last turn (1.25×). Independent of the image path's cache.
    const reused = Math.min(Math.max(prevCacheable, 0), cacheable);
    const grown = cacheable - reused;
    return reused * CACHE_READ_RATE + grown * CACHE_CREATE_RATE + coldTail * 1.0;
  }
  // Cold (first turn / TTL expiry): no warm cache for text either, so it
  // re-creates the whole cacheable prefix at the create rate — same event the
  // imaged path pays. Removes the phantom "free read" that fabricated a loss.
  return cacheable * CACHE_CREATE_RATE + coldTail * 1.0;
}

/** Weighted input cost pxpipe actually paid this turn. */
export function computeActualInputEff(
  inputTokens: number,
  cc: number,
  cr: number,
): number {
  return inputTokens + cc * CACHE_CREATE_RATE + cr * CACHE_READ_RATE;
}
