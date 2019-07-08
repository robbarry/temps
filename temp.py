#!/usr/bin/python3
import os
import sys
import pytz
import time
import yaml
import tzlocal
import requests
import subprocess
from datetime import datetime

from pathlib import Path
home = str(Path.home())

with open(os.path.join(home, "temps-config.yml"), 'r') as ymlfile:
    cfg = yaml.load(ymlfile, Loader=yaml.FullLoader)

config = cfg["default"]
upload_weather = False

if config.get("weatherfile", 0) != 0 and datetime.now().minute % 5 == 0:
    upload_weather = True
    r = requests.get("https://api.openweathermap.org/data/2.5/weather?lat=40.7442797&lon=-73.9552369&appid=a04295e8bd7a98fcd58567d52b0f4eff")
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
        with open(os.path.join(config["path"], config["weatherfile"]), "rb") as fh:
            last = fh.readlines()[-1].decode()
        
        if to_write != last:
            with open(os.path.join(config["path"], config["weatherfile"]), "a") as f:
                f.write(to_write)

p = subprocess.Popen(os.path.join(config["path"], "temp"), stdout=subprocess.PIPE, shell=True)
(output, err) = p.communicate()
p_status = p.wait()

now = datetime.now(tzlocal.get_localzone())
temp = output.strip().decode("utf-8")

with open(os.path.join(config["path"], config["tempsdata"]), "a") as f:
    f.write("{}\t{}\t{}\n".format(now, now.strftime("%Z"), temp))

subprocess.call(["R", "--no-save", "-f", os.path.join(config["path"], "temp-plot.r")])

time.sleep(10)

# subprocess.call(["scp", "/home/pi/temps/temp.txt", "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["tempsimg"]), "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["tempssummary"]), "web:/var/www/robbarry.org/html/repo/_site/"])
if upload_weather:
    subprocess.call(["scp", os.path.join(config["path"], "weather.png"), "web:/var/www/robbarry.org/html/repo/_site/"])
    subprocess.call(["scp", os.path.join(config["path"], "weather-short.png"), "web:/var/www/robbarry.org/html/repo/_site/"])
