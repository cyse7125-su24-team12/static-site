pipeline {
    agent any
    tools {
        nodejs 'Node 20'
    }
    environment {
        GH_TOKEN = credentials('github-pat')
    }
    stages {
        stage('Checkout') {
            steps {
            checkout([$class: 'GitSCM',
            branches: [[name: '*/main']],
            extensions: [[$class: 'CleanCheckout']],
            userRemoteConfigs: [[url: 'https://github.com/cyse7125-su24-team12/static-site.git', credentialsId: 'git-credentials-id']]
        ])
            }
        }
        stage('Setup semantic,github-release & yq'){
            when{
                expression{
                    return env.BRANCH_NAME == null
                }
            }
            steps{
                script {
                    sh '''
                        npm install -g \
                        semantic-release \
                        @semantic-release/changelog \
                        @semantic-release/github \
                        @semantic-release/commit-analyzer \
                        @semantic-release/release-notes-generator \
                        @semantic-release/exec \
                        @semantic-release/git 
                        ls -a 
                        npm install -g github-release-cli
                    '''
                }
            }
        }
        stage(' semantic release'){
            when{
                expression{
                    return env.BRANCH_NAME == null
                }
            }
            steps{
                script{
                    writeFile file: '.releaserc', text: '''
                    {
                        "branches": ["main"],
                        "plugins": [
                            "@semantic-release/commit-analyzer",
                            "@semantic-release/release-notes-generator",
                            "@semantic-release/changelog",
                            "@semantic-release/github",
                        ]
                    }
                    '''
                    sh '''
                    cat ./.releaserc
                    npx semantic-release
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Docker image pushed successfully!'
        }
        failure {
            echo 'Docker image push failed!'
        }
    }
}
