#!/usr/bin/python3
import os
import sys
import pytz
import time
import yaml
import tzlocal
import requests
import subprocess
from pathlib import Path
from datetime import datetime

home = str(Path.home())

with open(os.path.join(home, "temps-config.yml"), 'r') as ymlfile:
    cfg = yaml.load(ymlfile, Loader=yaml.FullLoader)

config = cfg["default"]
upload_weather = False

if config.get("weatherfile", 0) != 0 and datetime.now().minute % 1 == 0:
    upload_weather = True
    r = requests.get("https://api.openweathermap.org/data/2.5/weather?lat={}&lon={}&appid=a04295e8bd7a98fcd58567d52b0f4eff".format(config["lat"], config["lon"]))
    data = r.json()
    timezone = pytz.timezone(config["timezone"])
    stamp = datetime.fromtimestamp(data.get("dt", 0)).astimezone(timezone).isoformat()
    temp = data.get("main", {}).get("temp", "")    
    # r = requests.get("https://api.weather.gov/stations/{}/observations/latest".format(config["weatherstation"]))    
    # data = r.json().get("properties", {})
    # stamp = data.get("timestamp", 0)
    # temp = data.get("temperature", {}).get("value", "")
    if temp != "":
        temp = (temp - 273.15) * 9 / 5 + 32
        to_write = "{}\t{}\n".format(stamp, round(temp, 1))
        with open(os.path.join(config["path"], config["weatherfile"]), "r") as f:
            lines = f.readlines()

        lines.append(to_write)
        lines = set(lines)
        lines = list(lines)
        lines.sort()
        with open(os.path.join(config["path"], config["weatherfile"]), "w") as f:
            f.write("".join(lines))

subprocess.call(["R", "--no-save", "-f", os.path.join(config["path"], "temp-plot.r")])

time.sleep(10)

# subprocess.call(["scp", "/home/pi/temps/temp.txt", "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["tempsimg"]), "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["tempssummary"]), "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["nightname"]), "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["diffname"]), "web:/var/www/robbarry.org/html/repo/_site/"])
if upload_weather:
    subprocess.call(["scp", os.path.join(config["path"], "weather.txt"), "web:/var/www/robbarry.org/html/repo/_site/"])
    subprocess.call(["scp", os.path.join(config["path"], "weather.png"), "web:/var/www/robbarry.org/html/repo/_site/"])
    subprocess.call(["scp", os.path.join(config["path"], "weather-short.png"), "web:/var/www/robbarry.org/html/repo/_site/"])
