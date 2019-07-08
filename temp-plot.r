library("dplyr")
library("config")
library("suncalc")
library("lubridate")

home <- path.expand("~")
config <- config::get(file = paste0(home, "/temps-config.yml"))

data <- read.csv(paste0(config$path, "/", config$tempsdata), sep = "\t", header = F)
colnames(data) <- c("stamp", "timezone", "temp")
data$tzstamp <- ymd_hms(data$stamp)
data$rounded <- floor_date(data$tzstamp, unit = "hour")
data$day <- floor_date(data$tzstamp, unit = "day")

m <- mean(data$temp)
s <- sd(data$temp) 

data$hour <- hour(data$tzstamp)
hourly <-
  data %>%
    group_by(hour) %>%
    summarize(avg = mean(temp), sd = sd(temp))

sumdata <-
  data %>%
    filter(now() - rounded < (7 * 24 * 60)) %>%
    group_by(rounded) %>%
    summarize(test = mean(temp))

png(paste0(config$path, "/", config$tempssummary), width=1000, height=700)

big_range = c(min(with_tz(sumdata$rounded, tzone = config$timezone)), max(with_tz(sumdata$rounded, tzone = config$timezone)))

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
  for(j in 1:NROW(hourly)) {
    rect(
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) - 1/2), config$timezone), hourly[j, "avg"] + hourly[j, "sd"],
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) + 1/2), config$timezone), hourly[j, "avg"] - hourly[j, "sd"],
      border = NA,
      col = rgb(0, 1, 0, .15)
    )
  }
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
little_range = c(min(with_tz(m_data$tzstamp, config$timezone)), max(with_tz(m_data$tzstamp, config$timezone)))
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
  for(j in 1:NROW(hourly)) {
    rect(
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) - 1/2), config$timezone), hourly[j, "avg"] + hourly[j, "sd"],
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) + 1/2), config$timezone), hourly[j, "avg"] - hourly[j, "sd"],
      border = NA,
      col = rgb(0, 1, 0, .15)
    )
  }
  start <- sun[i, "sunset"]
  end <- sun[i + 1, "sunrise"]
  rect(start, -10, end, 150, col = rgb(0, 0, 0, .15), border = NA)
}

dev.off()

weather <- read.csv(paste0(config$path, "/", config$weatherfile), sep = "\t", header = F, stringsAsFactors = F)
colnames(weather) <- c("stamp", "temp")
weather$stamp <- ymd_hms(weather$stamp)

p_weather <- weather %>%
  filter(now() - stamp < days(7))

png(paste0(config$path, "/weather.png"), width=1000, height=300)
plot(with_tz(p_weather$stamp, tzone = "America/New_York"), p_weather$temp,
     frame = F, pch = 16,
     xlab = "Hour",
     ylab = "Temp", col = "black",
     xlim = big_range)

for(i in 1:(NROW(sun) - 1)) {
  for(j in 1:NROW(hourly)) {
    rect(
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) - 1/2), config$timezone), hourly[j, "avg"] + hourly[j, "sd"],
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) + 1/2), config$timezone), hourly[j, "avg"] - hourly[j, "sd"],
      border = NA,
      col = rgb(0, 1, 0, .15)
    )
  }
  start <- sun[i, "sunset"]
  end <- sun[i + 1, "sunrise"]
  rect(start, -10, end, 150, col = rgb(0, 0, 0, .15), border = NA)
}


dev.off()

p_weather <- weather %>%
  filter(now() - stamp < hours(36))

png(paste0(config$path, "/weather-short.png"), width=1000, height=300)
plot(with_tz(p_weather$stamp, tzone = "America/New_York"), p_weather$temp,
     frame = F, pch = 16,
     xlab = "Hour",
     ylab = "Temp", col = "black",
     xlim = little_range)

for(i in 1:(NROW(sun) - 1)) {
  for(j in 1:NROW(hourly)) {
    rect(
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) - 1/2), config$timezone), hourly[j, "avg"] + hourly[j, "sd"],
      with_tz(ymd(sun[i, "date"]) + dhours(as.numeric(hourly[j, "hour"]) + 1/2), config$timezone), hourly[j, "avg"] - hourly[j, "sd"],
      border = NA,
      col = rgb(0, 1, 0, .15)
    )
  }
  start <- sun[i, "sunset"]
  end <- sun[i + 1, "sunrise"]
  rect(start, -10, end, 150, col = rgb(0, 0, 0, .15), border = NA)
}

dev.off()

