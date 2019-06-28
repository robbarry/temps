library("dplyr")
library("config")
library("suncalc")
library("lubridate")

config <- config::get(file = "/home/pi/temps-config.yml")

data <- read.csv(paste0(config$path, "/", config$tempsdata), sep = "\t", header = F)
colnames(data) <- c("stamp", "timezone", "temp")
data$tzstamp <- ymd_hms(data$stamp)
data$rounded <- floor_date(data$tzstamp, unit = "hour")
data$day <- floor_date(data$tzstamp, unit = "day")

m <- mean(data$temp)
s <- sd(data$temp) 

sumdata <-
  data %>%
    filter(today() - rounded < (7 * 24 * 60)) %>%
    group_by(rounded) %>%
    summarize(test = mean(temp))

png(paste0(config$path, "/", config$tempssummary), width=1000, height=700)

plot(with_tz(sumdata$rounded, tzone = config$timezone), sumdata$test,
    type = "h", frame = F, lwd = 5, lend = 1,
    xlab = "Hour",
    ylab = "Temp",
    col = rgb(.75, 0, 0, 1),
    main = paste0(config$tempstitle, " [hourly]"))

sundays <- unique(as.Date(data$day))
sundays <- c(min(sundays) - 1, sundays, max(sundays) + 1)
sun <- getSunlightTimes(sundays, lat = config$lat, lon = config$lon, keep = c("sunrise", "sunset"), tz = "America/New_York")

for(i in 1:(NROW(sun) - 1)) {
  start <- sun[i, "sunset"]
  end <- sun[i + 1, "sunrise"]
  rect(start, -10, end, 150, col = rgb(0, 0, 0, .15), border = NA)
}

dev.off()

m_data <- subset(
  data,
  now() - data$tzstamp < (36 * 60 * 60)
)

png(paste0(config$path, "/", config$tempsimg), width=1000, height=700)

plot(with_tz(m_data$tzstamp, config$timezone),
      m_data$temp,
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

# ls <- loess.smooth(x = data$tzstamp, y = data$temp, span = .25)

# lines(ls$x,
#         ls$y,
#         lwd = 3)

current <- data[nrow(data), "temp"]
abline(h = current, col = "darkgreen", lty = 1, lwd = 1)
p <- 1
if (current > m) p <- 3
text(m_data[1, "tzstamp"], current, round(current, 1), pos = p, col = "darkgreen")

for(i in 1:(NROW(sun) - 1)) {
  start <- sun[i, "sunset"]
  end <- sun[i + 1, "sunrise"]
  rect(start, -10, end, 150, col = rgb(0, 0, 0, .15), border = NA)
}

dev.off()
