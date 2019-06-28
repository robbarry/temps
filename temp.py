#!/usr/bin/python3

import os
import sys
import time
import yaml
import tzlocal
import subprocess
from datetime import datetime

with open("/home/pi/temps-config.yml", 'r') as ymlfile:
    cfg = yaml.load(ymlfile, Loader=yaml.FullLoader)

config = cfg["default"]

p = subprocess.Popen(os.path.join(config["path"], "temp"), stdout=subprocess.PIPE, shell=True)
(output, err) = p.communicate()
p_status = p.wait()

now = datetime.now(tzlocal.get_localzone())
temp = output.strip().decode("utf-8")

with open(os.path.join(config["path"], config["tempsdata"]), "a") as f:
    f.write("{}\t{}\t{}\n".format(now, now.strftime("%Z"), temp))

subprocess.call(["R", "--no-save", "-f", os.path.join(config["path"], "temp-plot.r")])

# subprocess.call(["scp", "/home/pi/temps/temp.txt", "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["tempsimg"]), "web:/var/www/robbarry.org/html/repo/_site/"])
subprocess.call(["scp", os.path.join(config["path"], config["tempssummary"]), "web:/var/www/robbarry.org/html/repo/_site/"])
