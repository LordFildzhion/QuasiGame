# 12g. `ResonanceForeignDriver::releaseString()` corrupts the heap — ✅ fixed 2026-08-15

Status: historical record. Scope: the date, source tree and rig recorded below.

[Current guidance](../../issues/README.md) · [History index](README.md)

This records what was reported at the time, including claims later corrected. An old
“open”, “fixed”, deadline or command is not a present-day instruction or verification.

## Recorded change and evidence

<a id="history-12g-resonanceforeigndriverreleasestring-corrupts-the-heap---fixed-2026-08-15"></a>

### 12g. `ResonanceForeignDriver::releaseString()` corrupts the heap — ✅ fixed 2026-08-15

**TRANSFERS UNCHANGED — the fix crossed.** `R:\src\ResonanceForeignDriver\lib.cpp:150` carries it,
with the reasoning in a comment, and the 200-round-trip check was re-run under Qt 6
(`R:\src\docs\qa\rfd-qt6-final.log`, `"stringRoundTrips": 200`).

`ResonanceForeignDriver/lib.cpp:146`:

```cpp
EXPORT void releaseString(ResultString str)
{
    delete reinterpret_cast<QByteArray*>(str)->data();   // frees the interior data pointer
}
```

`QByteArray::data()` points *inside* the array's allocation, past the `QArrayData` header, so
`delete`-ing it is a free of an address the allocator never handed out. The fix is one word:
`delete reinterpret_cast<QByteArray*>(str);`.

Every FFI client hits it, because `resonance_foreign_driver.py`'s `_asString()` — the only way
to read `getServiceParameters()` or `getServiceTransitions()` — calls it on every result. The
process dies with `0xC0000374 STATUS_HEAP_CORRUPTION` on the first call, with no message.

Found 2026-08-14 while driving the merged `nvx` service from Python. **Fixed 2026-08-15** and
rebuilt; verified with 200 consecutive `getServiceTransitions` + `getServiceParameters` round
trips through `releaseString()` without a crash.

The Python wrapper was fixed with it: `getServiceParameters`, `getServiceTransitions`,
`sendTransitionToService` and `sendParametersToService` passed `str` straight into a
`c_char_p` argument (the other methods encode), so callers had to hand them `bytes`. They now
encode, and the two `send*` functions return the SDK's `bool` instead of a truncated int.

