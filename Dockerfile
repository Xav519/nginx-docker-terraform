# Use Nginx Alpine image
FROM nginx:alpine

# Copy static website into Nginx folder
COPY app/index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80
