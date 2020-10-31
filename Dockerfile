#############################
#     设置公共的变量         #
#############################
FROM danxiaonuo/hugo:latest AS dependencies

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/blog
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=golang
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=alpine
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG VCS_REF
ENV VCS_REF=$VCS_REF



# ***** 设置变量 *****

# HUGO站点路径
ARG HUGO_PATH=/blog
ENV HUGO_PATH=$HUGO_PATH
# blog访问令牌
ARG accessUserName=danxiaonuo
ENV accessUserName=$accessUserName
ARG accessToken=rN1t4mdgSPT-RZymyfbX
ENV accessToken=$accessToken

# ##############################################################################

####################################
#          构建运行环境             #
####################################
FROM dependencies AS build

# ***** 工作目录 *****
WORKDIR ${HUGO_PATH}


# ***** 克隆源码并生成静态文件 *****
RUN set -eux \
    && git clone --progress https://$accessUserName:$accessToken@gitlab.com/danxiaonuo/blog.git ${HUGO_PATH} \
    && git submodule update --init --recursive \
    && /usr/bin/hugo || true \
    && python3 /usr/bin/hugo-encryptor.py || true \
    && find . -name "*.md" | xargs rm -Rf
	
	
# ##############################################################################

##########################################
#         构建基础镜像                    #
##########################################
# 
# 指定创建的基础镜像
FROM danxiaonuo/nginx:latest


# 工作目录
WORKDIR /www/blog

# 拷贝资源文件
COPY --from=build /blog/public /www/blog
COPY conf/blog/vhost/default.conf /data/nginx/conf/vhost/default.conf

# 容器信号处理
STOPSIGNAL SIGQUIT

# 入口
ENTRYPOINT ["dumb-init"]

# 启动命令
CMD ["nginx", "-g", "daemon off;"]
