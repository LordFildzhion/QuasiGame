import QtQuick 2.15
import Resonance 3.0
import easy.colors 1.0

/**
 * Everything about one viewer that survives a restart, stored as JSON in a service parameter.
 *
 * Keys that are no longer read are simply ignored on load, and keys that are missing keep their
 * default, so an older saved configuration still opens -- it just does not carry the settings
 * that did not exist when it was written.
 */
QtObject {
    id: root
    signal changed()

    property string parameter_name: ""
    property string parameter_group: ""
    property string parameter_label: ""
    /// Sort position within the parameter group. Every parameter defaulting to index 0 leaves
    /// the tab's order unspecified, so two viewers' stream and settings entries came out in a
    /// different arrangement on each run.
    property int parameter_index: 0

    property var variables: [
        "axis_time_max",

        "stream_mode",

        "filter_highpass",
        "filter_lowpass",
        "filter_notch",
        "filter_notchWidth",
        "filter_notchHarmonics",
        "filter_highpass_enabled",
        "filter_lowpass_enabled",
        "filter_notch_enabled",
        "filter_type",
        "filter_order",

        "reference_mode",
        "reference_channel",

        "catch_level",
        "catch_edge",

        "lineWidth",
        "trace_color_mode",
        "antialias",
        "rows_per_page",
        "stacked",
        "scale_bar",
        "hide_constant_bits",
        "gutter_width",

        "head_mode",
        "head_scale",
        "head_image_cx",
        "head_image_cy",
        "head_image_opacity",
        "head_background",
        "head_outline",
        "head_good",
        "head_fair",
        "head_poor",
        "head_average_seconds",
        "head_disc",
        "head_show_names",
        "head_view",
        "head_field_variant",
        "head_field_labels",
        "head_field_auto_limit",
        "head_field_limit",
        "head_field_contours",
        "head_field_conv",
        "head_trace_auto_amplitude",
        "head_trace_amplitude",
        "head_trace_labels",
        "head_trace_frames",
        "head_trace_scale",

        "epoch_cursor_ms",

        "epoch_cut_enabled",
        "epoch_cut_show_sweep",
        "epoch_cut_stamp",
        "epoch_cut_use_block_timestamps",
        "epoch_cut_trigger_channel",
        "epoch_cut_trigger_mode",
        "epoch_cut_trigger_bit",
        "epoch_cut_trigger_level",
        "epoch_cut_trigger_edge",
        "epoch_cut_pre_ms",
        "epoch_cut_post_ms",
        "epoch_cut_refractory_ms",
        "epoch_cut_code_mask",
        "epoch_cut_codes",
        "epoch_cut_marker_allowance_ms",

        "epoch_average_show",
        "epoch_average_method",
        "epoch_average_all",
        "epoch_average_window",
        "epoch_average_all_bins",
        "epoch_average_bin",

        "epoch_attribution_enabled",
        "epoch_perception_latency_ms",
        "epoch_grouped_by_stimulus",
        "epoch_shown_stimulus_types",

        "epoch_budget_mb",
        "epoch_list_visible",

        "epoch_publish_counters",

        "background",
        "grid_color",
        "grid_middleLine_color",
        "grid_visible",
        "grid_middleLine_visible",

        "channel_state"
    ]

    property Parameters json_param: Parameters {
        String {
            id: json
            name: parameter_name + "settings"
            group: parameter_group
            label: parameter_label + "settings"
            index: root.parameter_index
        }

        Connections {
            target: json
            function onValueChanged() {
                if (json.value === "")
                    return
                let cfg
                try {
                    cfg = JSON.parse(json.value)
                } catch (e) {
                    console.warn("Plot settings are not valid JSON, ignoring:", e)
                    return
                }
                variables.forEach(function (prop) {
                    if (cfg[prop] !== undefined) {
                        if (ColorUtils.isQtColor(root[prop])) {
                            root[prop] = qolor(cfg[prop])
                        } else {
                            root[prop] = cfg[prop]
                        }
                    }
                })
            }
        }

        Connections {
            target: root
            function onChanged() {
                let new_json = {}
                variables.forEach(function (name) {
                    if (ColorUtils.isQtColor(root[name])) {
                        new_json[name] = root[name].toString()
                    } else {
                        new_json[name] = root[name]
                    }
                })
                json.value = JSON.stringify(new_json)
            }
        }
    }

    Component.onCompleted: {
        variables.forEach(function (name) {
            let prop = "on" + name[0].toUpperCase() + name.slice(1) + "Changed"
            root[prop].connect(function () { root.changed() })
        })
        root.changed()
    }

    // --- which viewer ---------------------------------------------------------------------------
    /**
     * Whether this connector is shown as a scrolling sweep or as an epoch.
     *
     * "auto" reads the answer off the stream: a per-channel `window_start_ms` is the declaration
     * "this is epoched", and StreamView switches on it. The other two values, "epoch" and
     * "continuous", overrule that verdict.
     *
     * An override exists at all because ANY automatic verdict will be wrong for somebody -- a
     * producer that has not been given the metadata yet, an epoch stream somebody wants to watch
     * scroll -- and the operator must be able to say so in one click rather than by editing a
     * service. An unknown value here is read as "auto", so a blob written by a newer build opens
     * in an older one without a fight.
     *
     * A string rather than an int: it is written into a JSON blob a human reads.
     */
    property string stream_mode: "auto"

    // --- time ---------------------------------------------------------------------------------
    property double axis_time_max: 3

    // --- filters ------------------------------------------------------------------------------
    property double filter_highpass: 3
    property double filter_lowpass: 35
    property double filter_notch: 50
    property double filter_notchWidth: 1
    property int filter_notchHarmonics: 1
    property bool filter_highpass_enabled: false
    property bool filter_lowpass_enabled: false
    property bool filter_notch_enabled: false
    property int filter_type: TimeSeriesReceiver.Butterworth
    property int filter_order: 4

    // --- reference ----------------------------------------------------------------------------
    property int reference_mode: 0
    property int reference_channel: 0

    // --- catch (auto-pause on a level crossing) -----------------------------------------------
    /// Level in base units, matching the channel's own scale.
    property double catch_level: 0
    /// TimeSeriesReceiver.RisingEdge / FallingEdge / EitherEdge.
    property int catch_edge: 0
    // Not persisted, and not settable either:
    // - the *source* is whatever single channel is selected, so there is nothing to store;
    // - the split either side of the crossing is fixed at half, because wanting more lead-in
    //   means wanting a longer window and the time range already does that;
    // - whether a catch is *armed*, because reopening a saved viewer into a display that pauses
    //   itself a second later, for a reason recorded in a file nobody has looked at, is not a
    //   state worth restoring.

    // --- appearance ---------------------------------------------------------------------------
    property double lineWidth: 1
    /**
     * Where a trace's colour comes from: "palette" or "scalp".
     *
     * "palette" is what this viewer has always done -- the per-channel override, else the group's
     * colour, else the six-entry list -- and stays the default, so an existing configuration opens
     * unchanged. "scalp" colours each EEG electrode by WHERE IT IS, reproducing the palette the
     * MATLAB prune UI draws its traces in. Anything unrecognised, including a blob written before
     * this key existed, reads as "palette". See ChannelModel::traceColorMode.
     */
    property string trace_color_mode: "palette"
    property bool antialias: true
    /// 0 means every row is on screen at once.
    property int rows_per_page: 0
    /**
     * Overlay every row on one shared axis instead of giving each its own lane.
     *
     * The lane layout answers "what is each channel doing"; this answers "how do these channels
     * compare", which is a different question — a latency between two traces, or one electrode
     * drifting away from the rest, is invisible when each has its own baseline.
     */
    property bool stacked: false
    /**
     * A reference bar of known amplitude in the corner of the plot.
     *
     * Comparing traces by eye needs a length to compare against — "that deflection is about two of
     * these" — and the value is rounded to one people quote, 10 uV or 1 mV, rather than to whatever
     * makes a tidy bar.
     */
    property bool scale_bar: false
    property bool hide_constant_bits: true
    /// Width of the channel-name column, dragged by its divider.
    property int gutter_width: 51

    // --- head map ------------------------------------------------------------------------------
    /// Show the scalp map instead of the traces. Persisted, unlike the catch's armed state: this
    /// is how the operator wants to look at the stream, not a transient condition.
    property bool head_mode: false
    /// Thresholds in the channel's displayed units -- kOhm on an impedance stream. Defaults match
    /// what the impedance rig has always used.
    property double head_good: 10
    property double head_fair: 20
    property double head_poor: 35
    /// Seconds averaged into each electrode's figure.
    property double head_average_seconds: 1.0
    /// Disc diameter as a fraction of the map's side. 0 means "size it from the montage", which
    /// is what makes a 12-channel and a 128-channel cap both readable without an adjustment.
    property double head_disc: 0
    property bool head_show_names: true

    /**
     * WHICH scalp map, out of THREE, and they are mutually exclusive:
     *
     *      "discs"   one coloured disc per electrode -- the impedance view (HeadView)
     *      "field"   EEGLAB's interpolated topoplot  -- the potential surface (TopoView)
     *      "traces"  one miniature epoch per electrode at its own scalp position (EpochGridView)
     *
     * Mutually exclusive because they are three answers to the same question drawn by three
     * different rules, and laying any two of them over each other would put a mark coloured by
     * one rule on top of a surface produced by another.
     *
     * A string rather than an enum or a pair of bools: it is written into a JSON blob a human
     * reads, and anything this file does not recognise -- including a blob written before the key
     * existed, or before "traces" existed -- falls back to what the reading view has always
     * shown. ⚠ A NEW VALUE IS AS BACKWARD-COMPATIBLE AS A NEW KEY: no configuration written
     * before today can say "traces", and none of them needs to.
     *
     * ⚠ WHICH VIEW HONOURS WHICH VALUE. The scrolling sweep draws "field" as the field and
     * everything else as the discs: a trace array is one stimulus-locked window per electrode, and
     * a sweep has no epochs to put in the cells. The epoch viewer draws "traces" as the array and
     * everything else as the field: the discs are an impedance instrument reading a running mean
     * of a CONTINUOUS stream over `head_average_seconds`, which one window replaced whole does not
     * have. Only one of the two views is on screen at a time (see StreamView), so an operator
     * never sees the fallback happen -- but it is a fallback, and it is stated here rather than
     * discovered.
     *
     * NOT a service parameter. Names are screened once, up front, so a parameter added late can
     * never be filled in from a configuration saved before it existed; a key inside the settings
     * blob costs nothing and restores.
     */
    property string head_view: "discs"

    /// "diverging" (the default, argued in colormap.hpp) or "jet" for comparing against a
    /// published MATLAB figure. Not a preference so much as a matching exercise.
    property string head_field_variant: "diverging"
    /// Electrode names on the field. Off by default: 64 labels over an interpolated map is a
    /// wall of text, and the names are what the gutter is for.
    property bool head_field_labels: false
    /**
     * Take the colour limit from the data (EEGLAB's absmax over the grid) rather than from
     * @ref head_field_limit.
     *
     * On by default. A fixed limit is what you want once you are comparing two epochs against
     * each other -- an auto scale makes every map look equally strong -- but it has to be set
     * from a map you have already seen, so the first one has to be automatic.
     */
    property bool head_field_auto_limit: true
    /// Half-range in BASE units (volts), the scale spanning [-limit, +limit]. 0 means "never
    /// set", which reads as automatic whatever @ref head_field_auto_limit says.
    property double head_field_limit: 0
    /**
     * EEGLAB's `numcontour`: isolines drawn over the field. 0 draws none.
     *
     * 0 by default, which is a deliberate difference from EEGLAB's own default of 6: the field
     * view shipped without isolines, and turning them on for everyone would change every map
     * already on screen. The levels are EEGLAB's -- evenly spaced across the FIELD's range, which
     * overshoots the readings -- and topoview.hpp says why that matters.
     */
    property int head_field_contours: 0
    /**
     * EEGLAB's `conv`: limit the drawn map to the electrode hull.
     *
     * Off by default, i.e. the whole plot disk, which is what the view has always drawn. What it
     * changes is what is VISIBLE; the field, and therefore the colour scale, is identical either
     * way.
     */
    property bool head_field_conv: false

    // --- head map: the trace array ("traces") --------------------------------------------------
    /**
     * Take the array's ONE shared amplitude from the montage's own group scale -- the widest
     * @c ChannelModel::effectiveRange over the electrodes on the map -- rather than from
     * @ref head_trace_amplitude.
     *
     * On by default, for the same reason the field's limit is: a fixed scale is what you want once
     * you are comparing two epochs, but it has to be set from an array you have already seen.
     *
     * ⚠ There is no per-cell autoscale, here or behind this. The array exists so that the cells
     * are COMPARABLE; a scale per cell would make every trace fill its box.
     */
    property bool head_trace_auto_amplitude: true
    /// Half-height of every cell in BASE units (volts). 0 means "never set", which reads as
    /// automatic whatever @ref head_trace_auto_amplitude says.
    property double head_trace_amplitude: 0
    /// Electrode names above the cells. ON by default, unlike @ref head_field_labels: a cell is a
    /// small shape in a crowd of small shapes, and an unnamed one has to be found by counting.
    property bool head_trace_labels: true
    /// A faint box around every cell. Off by default -- sixty-four boxes is a lot of ink for a
    /// fact the traces already state -- but it is how you check a dense montage is not overlapping.
    property bool head_trace_frames: false
    /**
     * Cell width as a fraction of side/sqrt(n), the array's only size control.
     *
     * ⭐ 0.72 is tepService's own number and is kept as the default so the ported layout is what
     * an operator sees first.
     *
     * ⚠ MEASURED on the shipped 64-channel montage, 1516x989 window, by
     * `R:\\tools\\qa\\epoch_grid_shot.qml`: at 0.72, **48 of the 2016 cell pairs overlap**; at 0.55,
     * 16 do. The closest pair of electrode CENTRES on that cap is F3/F5 at 49.5 px against a
     * 69.3 px cell, so nothing above about 0.50 clears it entirely.
     *
     * That is not a defect in the port. side/sqrt(n) sizes a cell for a UNIFORM grid of n cells,
     * and a 10-20 cap is denser along its central rows than a uniform grid is -- so the formula
     * is right and the montage is simply not uniform. What follows is that the size has to be
     * REACHABLE, not that the default is wrong: an operator who cannot separate the cells on a
     * dense cap is stuck with a picture whose neighbouring traces run together. Persisted, so it
     * is set once per cap rather than once per session.
     */
    property double head_trace_scale: 0.72

    // --- epoch time cursor -----------------------------------------------------------------
    /**
     * Where the epoch viewer's time cursor sits, in MILLISECONDS relative to the stimulus.
     *
     * Milliseconds, not a fraction of the window and not a sample index: a fraction means a
     * different latency in every window and a sample index means a different latency at every
     * rate, and this number is restored into a viewer whose stream may be neither the width nor
     * the rate it had when it was written. A latency is the thing the operator chose; it is the
     * thing that gets stored.
     *
     * It is CLAMPED into whatever window it lands in, and the clamp is captioned -- see
     * EpochReceiver::columnAtMs. NaN is not storable in JSON, so 0 is the default and means "the
     * stimulus instant", which is a real answer rather than a missing one.
     */
    property double epoch_cursor_ms: 0

    // --- ⭐ viewer-side epoching -------------------------------------------------------------------
    //
    // Cut epochs out of an ORDINARY CONTINUOUS STREAM around a trigger carried inside it, and show
    // them in the epoch viewer beside the sweep.
    //
    // ⚠ EVERY ONE OF THESE IS A BLOB KEY, not a service parameter, because none of them names a
    // stream. The only new stream slots this needs are declared in StreamView.qml, where a slot
    // added later could never be restored.

    /// Cut epochs from this viewer's continuous stream.
    property bool epoch_cut_enabled: false
    property bool epoch_cut_show_sweep: true

    /**
     * ⭐ WHAT THIS STREAM'S `created` FIELD NAMES: 0 last sample, 1 first sample, 2 the trigger
     * instant, 3 unknown.
     *
     * ⚠ MUST BE STATED. A continuous stream publishes no `epoch_stamp`, so nothing on the wire
     * says which sample its block timestamp refers to, and the three producers in this tree
     * disagree: every amplifier driver stamps roughly the last sample, signalGenerator's
     * continuous lane stamps the first. The default is the amplifier convention.
     *
     * It does NOT move the epochs: the trigger is found on a channel of the same block, so its
     * sample index is exact. It decides only the timestamp attached to an epoch and the marker
     * lookup that compares against it.
     */
    property int epoch_cut_stamp: TimeSeriesReceiver.StampLastSample
    property bool epoch_cut_use_block_timestamps: true

    /// Trigger lane, 1-based. 0 means the last channel, which is where the trigger word lives on
    /// every amplifier in this tree.
    property int epoch_cut_trigger_channel: 0
    /// TimeSeriesReceiver.TriggerBit (one bit of a trigger word) or .TriggerLevel (a crossing).
    property int epoch_cut_trigger_mode: TimeSeriesReceiver.TriggerBit
    property int epoch_cut_trigger_bit: 0
    property double epoch_cut_trigger_level: 0.5
    /// TimeSeriesReceiver.RisingEdge / FallingEdge / EitherEdge -- the Catch's enum, deliberately.
    property int epoch_cut_trigger_edge: TimeSeriesReceiver.RisingEdge

    /// Window edges in MILLISECONDS relative to the trigger; the pre edge is negative. The
    /// operator asked for milliseconds over sample indices on both bounds.
    property double epoch_cut_pre_ms: -100
    property double epoch_cut_post_ms: 400

    /// Minimum spacing between accepted triggers, ms. 0 accepts every edge.
    property double epoch_cut_refractory_ms: 0

    /// AND-ed with the trigger word before the code is read. A string, because it is hex and this
    /// blob is read by people.
    property string epoch_cut_code_mask: "0xffffffff"
    /// Codes to accept, comma-separated. Empty accepts every code.
    property string epoch_cut_codes: ""

    /// How long after a trigger a marker may still claim its epoch, ms. 0 is the strict rule --
    /// the newest record at or before the trigger.
    property double epoch_cut_marker_allowance_ms: 0

    // --- the epoch viewer: averaging -------------------------------------------------------------
    //
    // ⚠ ALL OF IT IN THE SETTINGS BLOB, none of it a service parameter. Parameter NAMES are
    // screened once, up front, so a parameter added later can never be restored from a saved
    // configuration; a key in this blob is ignored when unknown and keeps its default when
    // missing. The one thing that HAD to be a parameter -- the marker stream the condition labels
    // come from -- is declared in StreamView.qml for exactly that reason.

    /// Draw the average instead of the epoch that just arrived. Off means the last epoch.
    property bool epoch_average_show: false

    /**
     * "mean" | "median" | "trimmean10" | "trimmean20". Unknown values read as "mean".
     *
     * The number in the name is the TOTAL percentage removed, half from each end, as MATLAB's
     * trimmean does it: trimmean10 cuts 5% off each end. Below 20 epochs trimmean10 equals the
     * mean, and below 10 so does trimmean20.
     */
    property string epoch_average_method: "mean"

    /// Average every epoch since the last reset. False averages the last @ref
    /// epoch_average_window ACCEPTED epochs -- rejected ones are skipped, not counted.
    property bool epoch_average_all: true
    property int epoch_average_window: 100

    /// Average every condition together. False averages @ref epoch_average_bin alone.
    property bool epoch_average_all_bins: true
    /// The condition averaged when @ref epoch_average_all_bins is false. The empty string is the
    /// default bin -- where every epoch lands while no marker stream is connected.
    property string epoch_average_bin: ""

    // --- ⭐ stimulus attribution --------------------------------------------------------------

    /**
     * Label epochs from the stimulus service's `cue`/`pulse` events rather than from the marker
     * stream. Off by default, so a configuration saved before this existed labels the way it did.
     */
    property bool epoch_attribution_enabled: false

    /**
     * ⭐ THE PERCEPTION LATENCY, in milliseconds. A pulse landing less than this after a cue onset
     * is attributed to the interval BEFORE it, because the subject has not perceived the new cue
     * yet.
     *
     * DEFAULT 150 ms, and the basis is stated rather than assumed: the frontal differential
     * activity that separates target from non-target images in rapid visual categorisation
     * appears at about 150 ms after onset (Thorpe, Fize & Marlot, Nature 381:520-522, 1996), so
     * that is the earliest latency at which a visual cue's IDENTITY is demonstrably influencing
     * the brain. Earlier responses exist — striate cortex is reached at roughly 50-60 ms — but
     * they are driven by luminance and contrast, not by which cue it was.
     *
     * ⚠ THIS IS A VISUAL NUMBER. An auditory cue is faster and a somatosensory one faster still;
     * lower it for those. ⚠ It decides which condition every trial lands in, so it is saved with
     * the session settings AND written into the published epoch stream as
     * `epoch_perception_latency_ms`.
     */
    property double epoch_perception_latency_ms: 150

    /**
     * ⭐ Draw one trace per stimulus type instead of one per display source. ⚠ ISI, welcome, end
     * and the run edges are excluded entirely — not dimmed — and how many were excluded is on the
     * caption.
     */
    property bool epoch_grouped_by_stimulus: false

    /// Comma-separated stimulus types to draw. EMPTY MEANS EVERY TYPE PRESENT, which is stated on
    /// the caption rather than left to be inferred.
    property string epoch_shown_stimulus_types: ""

    /**
     * The memory NOTIFY THRESHOLD for the epoch store, in MEGABYTES. Default 2048; 0 turns the
     * notification off.
     *
     * ⚠ THIS KEY CHANGED MEANING and kept its name. It used to be a HARD CAP -- the store derived
     * a capacity from it and evicted the oldest epoch from then on. It is now a threshold at which
     * the operator is NOTIFIED and nothing is dropped: the ring grows on demand and never evicts on
     * its own, so eviction is only ever something the operator chose. Renaming it to
     * `epoch_notify_mb` would be cleaner and is safe (unknown keys are ignored on load and missing
     * keys keep their default); it has not been done.
     *
     * ⚠ Because of that history the value is screened before it is honoured: 512 (the old hard-cap
     * default) and anything below 16 both fall back to 2048, because they are far more likely to be
     * a stale cap than a threshold somebody meant.
     *
     * ⚠ Priced against samples PLUS the ring's own bookkeeping -- 104 bytes per slot, empty ones
     * included. Samples alone under-report by 9.92 MB at the 100000-slot ceiling, which is most of
     * a small stream. One epoch is 512 KB at 64 ch x 2000 samples and 14.6 MB at 73 ch x 25 kHz
     * x 2 s, so 2 GB is roughly 4000 and 147 epochs respectively.
     */
    property double epoch_budget_mb: 512

    /// Show the list of held epochs beside the plot.
    property bool epoch_list_visible: false

    // --- the epoch viewer: publishing (Stage 6) --------------------------------------------------
    //
    // ⚠ THE STREAM NAMES ARE NOT HERE. They are service parameters (`plotN_publishAverage`,
    // `plotN_publishEpochs`, declared in StreamView.qml), because an output stream name is
    // exactly the kind of thing another service is told to set, and because parameter names are
    // screened once up front -- a slot added later can never be filled in from a saved
    // configuration. Everything else about publishing is a key here, where an unknown key is
    // ignored and a missing one keeps its default.

    /**
     * Append `n_contributing` and `n_received` to the published average as two extra channels.
     *
     * On by default. An average file whose n is unknown is not analysable, and there is nowhere
     * else for n to go: stream metadata is announced once and n moves on every stimulus, so
     * putting it there would republish the stream per epoch. Off gives exact channel parity with
     * the epoch stream.
     */
    property bool epoch_publish_counters: true

    /**
     * Optional picture under the electrodes -- a topomap, an anatomical drawing, a photo of the
     * cap. Assigned from outside rather than owned here: one image serves both viewers, so the
     * Configurator holds the single parameter and hands it down. See @ref head_scale.
     */
    property string head_image: ""

    /**
     * Electrode spread, relative to the picture.
     *
     * With a picture the picture is the reference: it is fitted to the panel and the electrodes
     * are placed on top of it, with CED radius 0.5 landing at `head_scale` x half the picture's
     * displayed width. So `1.0` means the ear-level circle spans the whole picture.
     *
     * The default is the measured figure for `Bricks/topomap64_full_s.png` against the
     * `mks64_standard.ced` montage -- 1293 px per unit radius on a 1750 px image -- because that
     * is the pairing the rigs use, and a default that is right for it beats a round number that
     * is right for nothing.
     *
     * One number, adjusted until the electrodes sit on the ones drawn in the picture. The
     * alternative -- describing the picture's own geometry and deriving the rest -- is exact but
     * asks the operator for measurements they do not have; this asks them to drag a number until
     * it looks right, which is the thing they can actually do.
     *
     * Without a picture it is a plain zoom on the montage, which is fitted to the panel as before.
     */
    property double head_scale: 0.739

    /**
     * Where the head sits *within* the picture, as a fraction of its displayed size, for images
     * whose head is off-centre or that carry a caption down one side. The defaults are right for
     * anything symmetric.
     */
    property double head_image_cx: 0.5006
    property double head_image_cy: 0.4690
    property double head_image_opacity: 1.0
    /**
     * Behind the scalp map. Nine greys from white to black.
     *
     * White by default, unlike the traces: the topomaps that ship in `Bricks/` are black ink on a
     * transparent ground, so on a black panel the picture loads correctly and draws nothing you
     * can see. The disc colours are pastel and were chosen to carry dark text, so they read on a
     * pale ground too.
     */
    property color head_background: "#ffffff"
    /**
     * Draw the alignment circle over a picture.
     *
     * Off by default: with a picture the picture supplies the head, and drawing a second circle
     * over it is just clutter. Worth turning on for as long as it takes to set @ref head_scale.
     * Without a picture the outline is always drawn -- it is the display.
     */
    property bool head_outline: false

    property color background: "#000000"
    property color grid_color: "#3c3c3c"
    property color grid_middleLine_color: "#6e6e5a"
    property bool grid_visible: true
    property bool grid_middleLine_visible: true

    /// Per-channel appearance, groups and scales. Owned and serialised by ChannelModel.
    property string channel_state: ""
}
