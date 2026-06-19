import { describe, it, expect } from 'vitest';
import {
  computeBaselineInputEff,
  computeActualInputEff,
  CACHE_CREATE_RATE,
  CACHE_READ_RATE,
} from '../src/core/baseline.js';

/**
 * The text counterfactual must be warmth-aware. The old warmth-free version
 * always priced the cacheable prefix at the cheap read rate, which fabricated a
 * "free read" on cold/TTL-expiry turns — text would actually re-create the
 * prefix there, same as the imaged path. That phantom read showed up as a
 * dashboard loss on growth/cold turns even when imaging genuinely won.
 */
describe('computeBaselineInputEff (warmth-aware)', () => {
  const inp = 1000;
  const cc = 0;
  const cr = 0;

  it('credits nothing (returns actual) when the probe could not split the prefix', () => {
    const actual = computeActualInputEff(inp, cc, cr);
    expect(computeBaselineInputEff(5000, 0, inp, cc, cr, true, 0)).toBe(actual);
    expect(computeBaselineInputEff(5000, -1, inp, cc, cr, false, 0)).toBe(actual);
  });

  it('returns 0 for a non-positive baseline', () => {
    expect(computeBaselineInputEff(0, 100, inp, cc, cr)).toBe(0);
    expect(computeBaselineInputEff(-10, 100, inp, cc, cr)).toBe(0);
  });

  it('cold turn re-creates the whole cacheable prefix at the create rate', () => {
    // baseline=5000, cacheable=4000, coldTail=1000. No warm cache for text.
    const got = computeBaselineInputEff(5000, 4000, inp, cc, cr, false, 0);
    expect(got).toBe(4000 * CACHE_CREATE_RATE + 1000 * 1.0);
  });

  it('defaults to the cold (warmth-free) path when warm is omitted', () => {
    const explicit = computeBaselineInputEff(5000, 4000, inp, cc, cr, false, 0);
    const defaulted = computeBaselineInputEff(5000, 4000, inp, cc, cr);
    expect(defaulted).toBe(explicit);
  });

  it('warm turn reads the prefix it already had cached at the read rate', () => {
    // Same prefix size as last turn: fully reused, nothing grown.
    const got = computeBaselineInputEff(5000, 4000, inp, cc, cr, true, 4000);
    expect(got).toBe(4000 * CACHE_READ_RATE + 1000 * 1.0);
  });

  it('warm growth turn reads the reused prefix and creates only the growth', () => {
    // prev cached 3000, prefix grew to 4000: reused=3000, grown=1000.
    const got = computeBaselineInputEff(5000, 4000, inp, cc, cr, true, 3000);
    expect(got).toBe(3000 * CACHE_READ_RATE + 1000 * CACHE_CREATE_RATE + 1000 * 1.0);
  });

  it('caps reused at the current cacheable when the prefix shrank', () => {
    // prev cached 9000 but prefix is now 4000: reused=4000, grown=0.
    const got = computeBaselineInputEff(5000, 4000, inp, cc, cr, true, 9000);
    expect(got).toBe(4000 * CACHE_READ_RATE + 1000 * 1.0);
  });

  it('never prices a cold turn cheaper than a warm turn for the same prefix', () => {
    // The regression guard: cold must cost MORE than warm (no phantom free read).
    const cold = computeBaselineInputEff(5000, 4000, inp, cc, cr, false, 0);
    const warm = computeBaselineInputEff(5000, 4000, inp, cc, cr, true, 4000);
    expect(cold).toBeGreaterThan(warm);
  });
});
