# create the build instance 
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src                                                                    
COPY ./src ./

WORKDIR /src/Presentation/Nop.Web   

# build project   
RUN dotnet build Nop.Web.csproj -c Release

# build plugins
WORKDIR /src/Plugins
RUN set -eux; \
    for dir in *; do \
        if [ -d "$dir" ]; then \
            dotnet build "$dir/$dir.csproj" -c Release; \
        fi; \
    done

# publish project
WORKDIR /src/Presentation/Nop.Web   
RUN dotnet publish Nop.Web.csproj -c Release -o /app/published

WORKDIR /app/published

RUN mkdir logs bin

RUN chmod 775 App_Data \
              App_Data/DataProtectionKeys \
              bin \
              logs \
              Plugins \
              wwwroot/bundles \
              wwwroot/db_backups \
              wwwroot/files/exportimport \
              wwwroot/icons \
              wwwroot/images \
              wwwroot/images/thumbs \
              wwwroot/images/uploaded \
			  wwwroot/sitemaps

# create the runtime instance 
FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim-amd64 AS runtime

# add globalization support and required packages
RUN apt-get update && apt-get install -qqq libicu-dev libtiff-dev libgdiplus linux-libc-dev tzdata
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false


# copy entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

WORKDIR /app

COPY --from=build /app/published .

ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80
                            
ENTRYPOINT "/entrypoint.sh"
