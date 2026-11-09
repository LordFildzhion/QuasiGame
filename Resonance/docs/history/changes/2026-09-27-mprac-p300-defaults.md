# MPRAC P300 classifier defaults

2026-09-27. Follow-up to the [dedicated twelve-channel group study](../investigations/p300-practicum12-20260927.md): make its settings the venue defaults for personal training as well as group adaptation.

The source, deployed and development-runtime calibration/feedback/pretraining presets now explicitly store `low=.5`, `high=12`, `ridge=.003`, `startMs=100`, `endMs=600`, `meanMs=40`, with the existing HP_LP family, twelve cap channels and dedicated `q-6x6-practicum12-group.p300.json`. HP2/LP4, anti-alias, 20 ms feature stride and centered count-pooled Fisher remain the native implementation. Previously personal training inherited the generic 0.3 Hz high-pass default, although adaptation correctly used the frozen 0.5 Hz group recipe.

The MPRAC launcher also selects the dedicated group model as the active classifier if the classifier field is blank. It retains an already selected personal or legacy model, including the existing SPEED behavior for `.mat` files. No acquisition restart, presentation setting, monitor choice, timing, montage, recording option or global P300 default is changed.

Verification: all six source/deployed presets differ only in the six explicit numeric classifier options; their existing group path is confirmed. Launcher checks cover blank-model startup with stopped/running NVX, retained personal models and legacy selection. The existing native venue acceptance now asserts the numerical recipe in the trained twelve-channel model, including 100/600/40/20 samples at 1000 Hz, and exercises training/save/use/typing plus automatic group adaptation and typing. The private synthetic test graph uses the deployed venue and never operates physical hardware or operator services. Evidence: `R:/src/_test-output/mprac-p300-defaults-20260927`.

Completed: **21 UI checks passed**, zero failures, four synthetic recordings; the unrelated generic key-paced fixture was skipped. Source/deployed presets, launcher and README match exactly. No classifier retraining or service-binary deployment was needed.
