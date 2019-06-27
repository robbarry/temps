library("config")

config <- config::get(file = "/home/pi/temps-config.yml")

data <- read.csv(paste0(config$path, "/", config$tempsdata), sep = "\t", header = F)
colnames(data) <- c("stamp", "temp")
data$stamp <- as.POSIXct(data$stamp, tz = "BST")

m <- mean(data$temp)
s <- sd(data$temp) 

data <- subset(
  data,
  as.numeric(Sys.time()) - as.numeric(data$stamp) < (24 * 60 * 60)
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
        main = config$tempstitle)

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
if (current > m) p <- 3
text(data[1, "stamp"], current, round(current, 1), pos = p, col = "darkgreen")

dev.off()
