def getSemVerFromGit(grepFilter='.*'){
  // It may be worth adding the install instructions for git here to make sure it's there
  def tag = sh(returnStdout: true, script: 'git tag --contains | grep "${grepFilter}" | head -1').trim()
  def semver = findVersion(tag)
  return semver
}

def getSemVerFromPrevious(propFile='build.properties'){
  // Get the semver from the previous build
  copyArtifacts(
    filter: propFile,
    fingerprintArtifacts: true,
    projectName: currentBuild.projectName,
    selector: lastSuccessful(),
    target: '.'
  )
  def versionInfo = readFile(file: propFile)
  def version = findVersion(versionInfo)
  return version
}

@NonCPS
def findVersion(data, prefix='', pattern='.*(\\d+\\.\\d+\\.\\d+)'){
  def semver_match = "$data" =~ /${prefix}${pattern}/
  def semver = null
  try{
    semver = semver_match[0][1]
  } catch (Exception e){
    println "Did not find a match!"
    throw e
  } finally {
    semver_match = null
  }
  return semver
}

pipeline {
  agent {
    kubernetes {
      yaml '''apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins/jenkins-jenkins-agent: "true"
spec:
  containers:
  - name: docker
    image: docker:dind
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run
    - name: docker-config
      mountPath: /home/jenkins/.docker
    - name: private-git-vol
      mountPath: /home/jenkins/.ssh
      readOnly: true
  - name: docker-daemon
    image: docker:dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run
  volumes:
  - name: docker-socket
    emptyDir: {}
  - name: docker-config
    configMap:
      name: docker-config
  - name: private-git-vol
    secret:
      secretName: private-git
'''
    }
  }
  stages {
    stage('Pre-Build'){
      steps {
        container('docker'){
          sh('''
             apk add --no-cache aws-cli git
             git config --global --add safe.directory '*'
          ''')
          checkout scm
        }
      }
    }

    stage('Build Pulsar and MoP') {
      steps {
        container('docker') {
          script {
            version = getSemVerFromGit()
            sh('''
                docker version && DOCKER_BUILDKIT=1 docker build \
                --ssh default=/home/jenkins/.ssh/id_rsa \
                --progress plain \
                --tag 710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar \
                --file ./Dockerfile \
                .
            ''')
          }
        }
      }
    }

    stage('Push image to ECR'){
      steps {
        container('docker') {
          script {
            docker.withRegistry('https://710915658486.dkr.ecr.us-east-2.amazonaws.com', 'ecr:us-east-2:devops-ecr-credential') {
              docker.image('710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar').push("$version")
              docker.image('710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar').push("latest")
            }
          }
        }
      }
    }
  }
  post {
    success {
      // One or more steps need to be included within each condition's block.
      container('docker'){
        // Do something here to write the version used to a build.properties file
        writeFile file: 'build.properties', text: "version=$version"
        archiveArtifacts artifacts: 'build.properties'
      }
    }
  }
}

//podTemplate(yaml: '''
//    apiVersion: v1
//    kind: Pod
//    metadata:
//      labels:
//        jenkins/jenkins-jenkins-agent: "true"
//    spec:
//      containers:
//      - name: docker
//        image: docker:19.03.1
//        command:
//        - sleep
//        args:
//        - 99d
//        volumeMounts:
//        - name: docker-socket
//          mountPath: /var/run
//        - name: docker-config
//          mountPath: /home/jenkins/.docker
//        - name: private-git-vol
//          mountPath: /home/jenkins/.ssh
//          readOnly: true
//      - name: docker-daemon
//        image: docker:19.03.1-dind
//        securityContext:
//          privileged: true
//        volumeMounts:
//        - name: docker-socket
//          mountPath: /var/run
//      volumes:
//      - name: docker-socket
//        emptyDir: {}
//      - name: docker-config
//        configMap:
//          name: docker-config
//      - name: private-git-vol
//        secret:
//          secretName: private-git
//          defaultMode: 0600
//''') {
//  node(POD_LABEL) {
//
//    // Setup stage
//    stage('Pull Source') {
//
//      container('docker') {
//        checkout scm
//      }
//
//    }
//
//    // Build stage
//    stage('Build Pulsar and MoP Image') {
//
//      container('docker') {
//
//        stage('Build Pulsar and MoP') {
//          withCredentials([[
//              $class: 'AmazonWebServicesCredentialsBinding',
//              credentialsId: "devops-ecr-credential",
//              accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//              secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//          ]]) {
//            sh '''
//                docker version && DOCKER_BUILDKIT=1 docker build \
//                --ssh default=/home/jenkins/.ssh/id_rsa \
//                --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
//                --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
//                --progress plain \
//                --tag 710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar \
//                --file ./Dockerfile \
//                .
//            '''
//          }
//        }
//      }
//    }
//
//    // Publish stage
//    stage('Push Docker Images') {
//      container('docker') {
//        script {
//          docker.withRegistry('https://710915658486.dkr.ecr.us-east-2.amazonaws.com', 'ecr:us-east-2:devops-ecr-credential') {
//            // push each image as latest
//            docker.image('710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar').push("latest") //.push("${env.BUILD_NUMBER}")
//            docker.image('710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar').push("3.1.1.2") //.push("${env.BUILD_NUMBER}")
//          }
//
//        }
//
//      }
//
//    }
//
//  }
//}
