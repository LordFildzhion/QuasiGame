# Vendor SDK inquiries

**Status:** external questions and research proposals; reviewed for routing 2026-09-15. No new correspondence was sent. An unresolved vendor question is not evidence that the current driver still has the original defect.

## Routes and remaining questions

| ID | Family and evidence | Question to resolve | Next evidence |
|---|---|---|---|
| VENDOR-001 | NVX-52: [English](../../history/vendor-correspondence/nvx-sdk-questions.md), [Russian](../../history/vendor-correspondence/nvx-sdk-questions.ru.md), dated 2026-08-18 | Explain the vendor-reproduced 5 kHz sample loss; document status bits, latch width, initial invalid status frames, buffer cadence/overrun reporting and output readback semantics. | Attach exact DLL/firmware/rate/channel mode and a counter-based reproduction. Reconcile a reply with the driver before changing behavior. |
| VENDOR-002 | NVX136: [English](../../history/vendor-correspondence/nvx136-sdk-questions.md), [Russian](../../history/vendor-correspondence/nvx136-sdk-questions.ru.md), dated 2026-08-18 | Correct impedance buffer size/GND position; explain commands that interrupt impedance, sentinel meanings, unsupported mirror/battery functions and acquisition rate/channel constraints. | Preserve the historical observed values separately from the vendor's explanation. Current workarounds are in the [NVX136 reference](../../components/nvx136.md). |
| VENDOR-003 | Additional [Russian SDK questions](../../history/vendor-correspondence/SDK_questions_RU.docx) | Clarify the filter APIs, parameter meanings and units, valid sequences, trigger mirroring and impedance header contradictions. | Obtain a versioned header/manual or written answer with a minimal sample; the names below make image-only evidence searchable. |
| VENDOR-004 | [NVX improvement suggestions](../../history/vendor-correspondence/nvx-improvement-suggestions.md) | Discuss API/diagnostic improvements and transport ideas, including proposed PCIe options. | Keep a vendor feasibility response separate from any accepted repository architecture. |

The [author-question history](../../history/investigations/questions-for-author.md) records correspondence as sent in its own context. The copies above do not establish a delivery date, recipient, or later answer for every document. Record those explicitly when located; do not label every language variant as independently sent. English/Russian pairs are related versions of the same inquiry.

## Resolved application behavior is not a fresh vendor blocker

- NVX output argument handling was repaired and physical output subsequently observed. Old statements that it was never verified have later amendments in the [trigger campaign](../../history/investigations/report_trigger-validation.md).
- NVX136 cold start was later solved by a discarded voltage read immediately after opening. The old GetVersion hypothesis and recovery ladder are historical; see the [current component reference](../../components/nvx136.md).
- NVX136 mirroring was withdrawn from the applicable application path. A vendor request to document it does not authorize restoring an unsupported setter.

## Header facts present only in the illustrated inquiry

The following declarations are transcribed from the embedded SDK screenshots in `SDK_questions_RU.docx`. They are dated evidence, not verified declarations for a newer SDK:

```cpp
NVX_API int WINAPI NVXLoadFilterCoefficients(
    int Id, signed short *Coefficients, unsigned short Count);
NVX_API int WINAPI NVXSetFilterParameters(
    int Id, t_NVXFilterParameters *FilterParameters);
NVX_API int WINAPI NVXStartFiltering(int Id);
NVX_API int WINAPI NVXStopFiltering(int Id);
// Fields shown for t_NVXFilterParameters:
unsigned short Channel;
unsigned short Threshold;
unsigned int Divider;
```

The impedance header screenshot says `Size` is in **bytes**, approximately 750 ms per 32 electrodes, maximum impedance 300–500 kOhm and a 0–120 kOhm measurement range at ±15%; it requires GND and first-slot REF and names `INT_MAX`. Its `CountEeg + 1` size formula conflicts with the observed NVX136 `CountEeg + CountAux + 1` requirement. Keep that conflict explicit. Mirror API screenshots show `HANDLE` and unsigned-char-pointer arguments, while the historical application screenshot inverted `mirrorTriggers`; neither establishes supported hardware semantics.

All five embedded PNGs were inspected during the documentation review. The original illustrated document and correspondence remain historical evidence; the operator manuals are a separate reading route.
