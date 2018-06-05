import time
from beacontools import BtAddrFilter, BeaconScanner, IBeaconFilter, CYPRESS_BEACON_DEFAULT_UUID

def callback(bt_addr, rssi, packet, additional_info):
    print("<%s, %d> Major:%s %.1fdegC %.1f %%RH" % (bt_addr, rssi, packet.major, packet.cypress_temperature, packet.cypress_humidity))

scanner = BeaconScanner(callback,device_filter=BtAddrFilter(bt_addr="00:A0:50:29:34:D5"))
scanner.start()
time.sleep(6*60)
scanner.stop()


