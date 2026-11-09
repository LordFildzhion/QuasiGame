import ctypes
import platform
import os
import json


class Driver:
    def __init__(self, name):
        self._dll_directories = []
        if platform.system() == "Windows":
            resonance_path = os.environ.get('RESONANCE_PATH')
            if resonance_path:
                # Keep the handle alive for the lifetime of the driver.  Discarding the object
                # returned by add_dll_directory lets Python close the search directory again at
                # an arbitrary garbage-collection point.
                self._dll_directories.append(os.add_dll_directory(resonance_path))
                qt_path = os.path.join(os.path.dirname(resonance_path), 'qt', 'bin')
                if os.path.isdir(qt_path):
                    self._dll_directories.append(os.add_dll_directory(qt_path))
                library = os.path.join(resonance_path, 'ResonanceForeignDriver.dll')
            else:
                library = 'ResonanceForeignDriver.dll'
            self._lib = ctypes.CDLL(library)
        else:
            self._lib = ctypes.CDLL("libResonanceForeignDriver.so")
        
        self._lib.setUp.argtypes = [ctypes.c_char_p]
        
        self._lib.pollEvents.argtypes = []
        
        self._lib.outputMessageStream.restype = ctypes.c_size_t
        self._lib.outputMessageStream.argtypes = [ctypes.c_char_p]
        
        self._lib.sendMessage.argtypes = (ctypes.c_size_t, ctypes.c_char_p)
        
        self._messageCallback = ctypes.CFUNCTYPE(None, ctypes.c_char_p, ctypes.c_uint64)
        self._dataCallback = ctypes.CFUNCTYPE(None, ctypes.POINTER(ctypes.c_double), ctypes.c_uint, ctypes.c_uint, ctypes.c_uint64)
        
        self._callbacks = []
        
        self._lib.inputMessageStream.argtypes = (ctypes.c_char_p, self._messageCallback)
        self._lib.inputDataStream.argtypes = (ctypes.c_char_p, self._dataCallback)
        
        self._lib.loadConfig.argtypes = [ctypes.c_char_p]
        
        self._lib.getString.argtypes = [ctypes.c_void_p]
        self._lib.getString.restype = ctypes.c_char_p

        self._lib.releaseString.argtypes = [ctypes.c_void_p]

        self._lib.getServiceParameters.argtypes = [ctypes.c_char_p]
        self._lib.getServiceParameters.restype = ctypes.c_void_p

        self._lib.getServiceTransitions.argtypes = [ctypes.c_char_p]
        self._lib.getServiceTransitions.restype = ctypes.c_void_p

        self._lib.sendParametersToService.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        self._lib.sendParametersToService.restype = ctypes.c_bool

        self._lib.sendTransitionToService.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        self._lib.sendTransitionToService.restype = ctypes.c_bool

        self._lib.outputChannelStream.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_double]
        self._lib.outputChannelStream.restype = ctypes.c_size_t

        try:
            import numpy as np
            self._lib.sendChannelData.argtypes = [ctypes.c_size_t, ctypes.c_int, np.ctypeslib.ndpointer(dtype=np.float64, ndim=2, flags='C_CONTIGUOUS')]
        except:
            pass

        self._lib.setUp(bytes(name, 'utf-8'))

    def _asString(self, ret):
        result = self._lib.getString(ret)
        self._lib.releaseString(ret)
        return result
        
    def loadConfig(self, fileName):
        self._lib.loadConfig(bytes(fileName, 'utf-8'))
        
    def pollEvents(self):
        self._lib.pollEvents()
        
        
    def outputMessageStream(self, name):
        id = self._lib.outputMessageStream(bytes(name, 'utf-8'))
        
        def sendMessage(message):
            self._lib.sendMessage(id, bytes(message, 'utf-8'))
            
        return sendMessage

    def outputChannelsStream(self, name, channels, samplingRate):
        id = self._lib.outputChannelStream(bytes(name, 'utf-8'), channels, samplingRate)

        def sendChannelData(data):
            import numpy as np
            # The native ABI wants a row-major [samples, channels] block.  np.rows never
            # existed; the old wrapper therefore failed before making its first native call.
            values = np.ascontiguousarray(data, dtype=np.float64)
            if values.ndim != 2 or values.shape[1] != channels:
                raise ValueError('data must have shape (samples, %d)' % channels)
            self._lib.sendChannelData(id, values.shape[0], values)

        return sendChannelData

    def inputMessageStream(self, name, callback):
        cb = self._messageCallback(callback)
        self._callbacks.append(cb)
        self._lib.inputMessageStream(bytes(name, 'utf-8'), cb)
        
    def inputDataStream(self, name, callback, no_numpy=False):
        def cb_wrapper(data, channels, samples, timestamp):
            if no_numpy:
                arr = []
                i = 0
                for s in range(0, samples):
                    v = []
                    for c in range(0, channels):
                        v.append(data[i])
                        i += 1
                    arr.append(v)
            else:
                import numpy as np
                arr = np.zeros((samples, channels))
                i = 0
                for s in range(0, samples):
                    for c in range(0, channels):
                        arr[s,c] = data[i]
                        i += 1
            callback(arr, timestamp)
            
        cb = self._dataCallback(cb_wrapper)
        self._callbacks.append(cb)
        self._lib.inputDataStream(bytes(name, 'utf-8'), cb)

    @staticmethod
    def _utf8(value):
        return value if isinstance(value, bytes) else bytes(value, 'utf-8')

    def getServiceParameters(self, name):
        return json.loads(self._asString(self._lib.getServiceParameters(self._utf8(name))))

    def getServiceTransitions(self, name):
        return json.loads(self._asString(self._lib.getServiceTransitions(self._utf8(name))))

    def sendTransitionToService(self, name, transition):
        return self._lib.sendTransitionToService(self._utf8(name), self._utf8(transition))

    def sendParametersToService(self, name, parameters):
        if not isinstance(parameters, (str, bytes)):
            parameters = json.dumps(parameters)
        return self._lib.sendParametersToService(self._utf8(name), self._utf8(parameters))
