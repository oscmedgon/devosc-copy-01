def GIT_TAG = ''
def VERSION = ''
pipeline {
    agent any
    environment {
        GIT_AUTHOR_EMAIL = "${GIT_AUTHOR_EMAIL}"
        GIT_AUTHOR_NAME = "${GIT_AUTHOR_NAME}"
    }
    stages {
        stage('Initialize build') {
            agent any
            when {
                branch "master"
            }
            steps {
                echo "Setting up tag variable"
                withCredentials([
                    gitUsernamePassword(
                        credentialsId: 'GITHUB_CREDENTIALS',
                        gitToolName: 'git-tool'
                    )
                ]) {
                    sh("git fetch --tags")
                }
                sh("git tag -l")
                script {
                    GIT_TAG = sh(returnStdout: true, script: "git describe --abbrev=0 --tags").trim()
                    VERSION = "${GIT_TAG}-${BUILD_ID}-${GIT_COMMIT}"
                }
            }
        }
        stage('Build production image') {
            agent {
                docker {
                    image 'docker:dind'
                }
            }
            when {
                allOf {
                    branch "master"
                }
            }
            environment {
                IMAGE_BASE_NAME = "oscmedgon/devosc_blog"
                DOCKER_ACCESS_USERNAME = credentials('DOCKER_ACCESS_USERNAME')
                DOCKER_ACCESS_TOKEN = credentials('DOCKER_ACCESS_TOKEN')
                STACKBIT_API_KEY = credentials('STACKBIT_API_KEY')
            }
            steps {
                sh("docker login -u $DOCKER_ACCESS_USERNAME -p $DOCKER_ACCESS_TOKEN")
                sh("docker build \
                    -t $IMAGE_BASE_NAME:$VERSION \
                    --build-arg VERSION=$VERSION \
                    --build-arg STACKBIT_API_KEY=$STACKBIT_API_KEY \
                    .")
                sh("docker push $IMAGE_BASE_NAME:$VERSION")
            }
        }
        stage('Deploy production image') {
            agent {
                docker {
                    image 'dev0sc/kubectl:stable-arm64'
                    alwaysPull true
                }
            }
            when {
                allOf {
                    branch "master"
                }
            }
            environment {
                DEPLOYMENT = "devosc-blog-deployment"
                BASE_IMAGE = "oscmedgon/devosc_blog"
                NAMESPACE = "production"
                APP = "web"
                DOCKER_ACCESS_TOKEN = credentials('DOCKER_ACCESS_TOKEN')
            }
            steps {
                withCredentials([
                    file(credentialsId: 'KUBE_CONF', variable: 'KUBE_CONF'),
                ]) {
                    sh("mkdir ~/.kube")
                    sh "cp -v \$KUBE_CONF ~/.kube/config"
                }
                sh("kubectl -n ${NAMESPACE} set image deploy ${DEPLOYMENT} ${APP}=${BASE_IMAGE}:${VERSION} --record")
                sh("kubectl -n ${NAMESPACE} annotate deploy ${DEPLOYMENT} \
                    kubernetes.io/change-cause='Updated image of app ${APP} updated to ${VERSION}'")
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}
