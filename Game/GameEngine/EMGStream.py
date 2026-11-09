"""Deprecated compatibility names for the former in-engine UDP transport.

Networking now lives exclusively in the sibling Bridge package. Importing this
module never opens a socket and is retained only to provide a clear migration
message to old scripts.
"""


class EMGStreamReceiver:
    def __init__(self, *args, **kwargs):
        raise RuntimeError(
            "EMGStreamReceiver was removed from the game engine. "
            "Start Integration.run_game, which wires Bridge.udp_game_bridge to GameAPI."
        )
