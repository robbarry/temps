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
p = subprocess.Popen(os.path.join(config["path"], "temp"), stdout=subprocess.PIPE, shell=True)
(output, err) = p.communicate()
p_status = p.wait()

now = datetime.now(tzlocal.get_localzone())
temp = output.strip().decode("utf-8")

with open(os.path.join(config["path"], config["tempsdata"]), "a") as f:
    f.write("{}\t{}\t{}\n".format(now, now.strftime("%Z"), temp))
