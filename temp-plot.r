library("dplyr")
library("config")
library("suncalc")

config <- config::get(file = "/home/pi/temps-config.yml")

data <- read.csv(paste0(config$path, "/", config$tempsdata), sep = "\t", header = F)
colnames(data) <- c("stamp", "temp")
data$stamp <- as.POSIXct(data$stamp, tz = "BST")

m <- mean(data$temp)
s <- sd(data$temp) 

data$rounded <-
  as.POSIXct(
      floor(as.numeric(data$stamp) / 3600) * 3600,
      tz = "EST",
      origin = "1970-01-01"
    )

png(paste0(config$path, "/", config$tempssummary), width=1000, height=700)

sumdata <-
  data %>%
    filter(as.numeric(Sys.time()) - as.numeric(rounded) < (7 * 24 * 60 * 60)) %>%
    group_by(rounded) %>%
    summarize(test = mean(temp))

plot(sumdata, type = "h", frame = F, lwd = 5, lend = 1,
    xlab = "Hour",
    ylab = "Temp",
    col = rgb(.75, 0, 0, 1),
    main = paste0(config$tempstitle, " [hourly]"))

days <- as.POSIXct(paste0(unique(as.Date(sumdata$rounded)), " 00:00:00"), tz = "EST", origin = "1970-01-01")

sundays <- as.Date(days)
sundays <- c(min(sundays) - 1, sundays, max(sundays) + 1)
sun <- getSunlightTimes(sundays, lat = config$lat, lon = config$lon, keep = c("sunrise", "sunset"), tz = "America/New_York")

for(i in 1:(NROW(sun) - 1)) {
  start <- sun[i, "sunset"]
  end <- sun[i + 1, "sunrise"]
  rect(start, -10, end, 150, col = rgb(0, 0, 0, .15), border = NA)
}

dev.off()

data <- subset(
  data,
  as.numeric(Sys.time()) - as.numeric(data$stamp) < (25 * 60 * 60)
)

png(paste0(config$path, "/", config$tempsimg), width=1000, height=700)

data$stamp <- as.POSIXct(format(data$stamp, tz="EST"))

plot(data$stamp,
        data$temp,
        type = "l",
        lwd = 2,
        frame = F,
        col = "blue",
        xlab = "Time",
        ylab = "Temp",
        main = paste0(config$tempstitle, " [by minute]"))

abline(h = m, col = "red", lty = 2, lwd = 2)
abline(h = m - s, col = "black", lty = 2)
abline(h = m + s, col = "black", lty = 2)

ls <- loess.smooth(x = data$stamp, y = data$temp, span = .25)

lines(ls$x,
        ls$y,
        lwd = 3)

current <- data[nrow(data), "temp"]
abline(h = current, col = "darkgreen", lty = 1, lwd = 1)
p <- 1
print(current)
print(m)
if (current > m) p <- 3
text(data[1, "stamp"], current, round(current, 1), pos = p, col = "darkgreen")

dev.off()
