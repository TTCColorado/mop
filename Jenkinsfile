podTemplate(yaml: '''
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        jenkins/jenkins-jenkins-agent: "true"   
    spec:
      containers:
      - name: docker
        image: docker:19.03.1
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
        image: docker:19.03.1-dind
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
          defaultMode: 0600
''') {
  node(POD_LABEL) {

    // Setup stage
    stage('Pull Source') {

      container('docker') {
        checkout scm
      }
      
    }

    // Build stage
    stage('Build Pulsar and MoP Image') {

      container('docker') {

        stage('Build Pulsar and MoP') {
          withCredentials([[
              $class: 'AmazonWebServicesCredentialsBinding',
              credentialsId: "devops-ecr-credential",
              accessKeyVariable: 'AWS_ACCESS_KEY_ID',
              secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
          ]]) {
            sh '''
                docker version && DOCKER_BUILDKIT=1 docker build \
                --ssh default=/home/jenkins/.ssh/id_rsa \
                --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
                --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
                --progress plain \
                --tag 710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar \
                --file ./Dockerfile \
                .
            '''
          }
        }
      }
    }

    // Publish stage
    stage('Push Docker Images') {
      container('docker') {
        script {
          docker.withRegistry('https://710915658486.dkr.ecr.us-east-2.amazonaws.com', 'ecr:us-east-2:devops-ecr-credential') {
            // push each image as latest
            docker.image('710915658486.dkr.ecr.us-east-2.amazonaws.com/ttc_pulsar').push("latest") //.push("${env.BUILD_NUMBER}")
          }

        }

      }

    }

  }
}

