import os
import yaml
import requests

with open("/home/pi/temps-config.yml", 'r') as ymlfile:
    cfg = yaml.load(ymlfile, Loader=yaml.FullLoader)

config = cfg["default"]

for day in range(26, 30):
    for hour in range(0, 23):
        weather_url = "https://api.weather.gov/stations/KNYC/observations/2019-06-{}T{}:51:00+00:00".format(day, str(hour).zfill(2))
        r = requests.get(weather_url)
        weather = r.json()
        if "status" not in weather:            
            print(weather_url)
            data = weather.get("properties", {})
            stamp = data.get("timestamp", 0)
            temp = data.get("temperature", {}).get("value", "")
            if temp != "":
                temp = temp * 9 / 5 + 32
                to_write = "{}\t{}\n".format(stamp, round(temp, 1))
                try:
                    with open(os.path.join(config["path"], config["weatherfile"]), "rb") as fh:
                        last = fh.readlines()[-1].decode()
                except:
                    last = "none"
                
                if to_write != last:
                    with open(os.path.join(config["path"], config["weatherfile"]), "a") as f:
                        f.write(to_write)
                    print(to_write.strip())
