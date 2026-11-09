import resonance
from resonance import input
from resonance.pipe import (
    spatial,
    sosfilt,
    windowizer,
    transform_to_channels,
    csp_features
)
import numpy as np
import json

# • EEG_CHANNELS – [1 x N] int; индексы используемых каналов ЭЭГ (N = 57).
# • fs – [1 x 1] int; частота дискретизации сигнала (1000 Гц).
# • spatialW – [N x K] double; матрица пространственных фильтров CSP.
# • n_components – [1 x 1] int; количество выбранных CSP-компонент (K = 2).
# • sos_basic – [M x 6] double; коэффициенты основного полосового фильтра в формате SOS (M = 4).
# • sos – [M x 6] double или None; коэффициенты дополнительного узкополосного фильтра для выделения μ-ритма (M = 4).
# • w_lda – [K x 1] double; веса линейного классификатора LDA.
# • b_lda – [1 x 1] double; свободный член LDA.
# • probability – [1 x 1] double; вероятность класса 0 (1 - sigmoid(w_lda @ features + b_lda)).
# • lda_decision – [1 x 1] int; бинарное решение классификатора (0 или 1).


def load_params(json_filename):
    """
    Загрузка сохраненного классификатора из JSON файла
    """
    with open(json_filename, 'r') as f:
        data = json.load(f)
    
    return data

EEG_CHANNELS = [ 2,  3,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
       20, 21, 22, 23, 24, 25, 26, 28, 29, 32, 33, 35, 36, 37, 38, 39, 40,
       41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
       58, 59, 60, 62, 63]

def pipeline(filename_json):
    raw_signal = input(0)

    # 0. Load parameters
    params = load_params(filename_json)
    
    # 1. Пространственный фильтр 
    n_ch = 67 #raw_signal.shape[1] 
    spatial_transformation = (
        ((np.eye(n_ch)[:, EEG_CHANNELS]) * (10**6)) @ params["spatialW"]
    )  # combination of spatial filter and EEG channels filter
    
    rearranged = spatial(raw_signal, spatial_transformation) # for offline and real online
    #resonance.createOutput(rearranged, "spatial_out") # only channels and events
    
    filtered = sosfilt(rearranged, np.ascontiguousarray(params["sos_basic"]))       #  1 40 Hz
    
    if params["sos"] is not None:
        filtered = sosfilt(filtered, np.ascontiguousarray(params["sos"]))         # narrow band (e.g. 10 12 Hz)
    
    window_sec = 1.0
    step_sec = 0.1

    window_length = int(window_sec * params["fs"])
    step = int(step_sec * params["fs"])


    windowized = windowizer(filtered, window_length, step)
    
    features = csp_features(windowized, channels=params["n_components"])
    
    # 7. Классификатор LDA 
    
    def apply_lda_raw(wnd):
        score_raw = wnd @ params["w_lda"] + params["b_lda"]
        p = 1 / (1 + np.exp(-score_raw))  # вероятность класса 1
        return 1-p
    
    classified_raw = transform_to_channels(features, apply_lda_raw)
    resonance.createOutput(classified_raw, "probability")       # only channels and events 

    #resonance.createOutput(classified_raw, "lda_raw") # only channels and events 
    
    def apply_lda(wnd):
        score_raw = wnd @ params["w_lda"] + params["b_lda"]
        p = 1 / (1 + np.exp(-score_raw))  # вероятность класса 1
        score = 1 if p < 0.5 else 0
        #score = 1 if score_raw > 0 else 0
        return score

    classified = transform_to_channels(features, apply_lda)
    resonance.createOutput(classified, "lda_decision") # only channels and events 

    
    """
    # 8. Классификатор имени Анатолия

    def apply_naiveAnatolyan_raw(features):
        posterior_prob = np.zeros(features.shape)
        for ch in range(len(features)):
            posterior_prob[ch] = np.interp(features[ch], p.MdlA['bin'][ch], p.MdlA['value'][ch])
        posterior_prob = np.array(posterior_prob)
        numerator = np.prod(posterior_prob)
        denominator = np.prod(posterior_prob) + np.prod(1-posterior_prob)
        proba = round(numerator / denominator, 4)
        
        return proba

    
    classified_prob = transform_to_channels(features, apply_naiveAnatolyan_raw)
    resonance.createOutput(classified_prob, "naive_probability") # only channels and events 

    """

