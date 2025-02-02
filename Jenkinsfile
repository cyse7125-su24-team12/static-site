pipeline {
    agent any
    tools {
        nodejs 'Node 20'
    }
    environment {
        DOCKERHUB_REPO = 'bala699/csye7125'
        BUILD_NUMBER = 'latest'
        GH_TOKEN = credentials('github-pat')
        REPO_NAME = "static-site"
        REPO_OWNER = "cyse7125-su24-team12" // D
        DOCKER_BUILDER_NAME = 'static-builder'
    }
    stages {
        stage('Checkout') {
            when {
                expression {
                    return env.BRANCH_NAME == null
                }
            }
            steps {
            checkout([$class: 'GitSCM',
            branches: [[name: '*/main']],
            extensions: [[$class: 'CleanCheckout']],
            userRemoteConfigs: [[url: 'https://github.com/cyse7125-su24-team12/static-site.git', credentialsId: 'git-credentials-id']]
        ])
            }
        }
        stage('Setup Buildx') {
            when {
                expression {
                    // Check if the BRANCH_NAME is null
                    return env.BRANCH_NAME == null
                }
            }
            steps {
                script {
                    sh '''
                        mkdir -p ~/.docker/cli-plugins/
                        curl -sL https://github.com/docker/buildx/releases/download/v0.14.1/buildx-v0.14.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
                        chmod +x ~/.docker/cli-plugins/docker-buildx
                        export PATH=$PATH:~/.docker/cli-plugins
                        '''
                }
            }
        }
        stage('Setup hadolint')
        {
            when{
                expression{
                    return env.BRANCH_NAME != null
                }
            }
            steps {
                script {
                        sh '''
                        # Check if Hadolint is already installed and at the desired version
                        if ! command -v hadolint &>/dev/null || [[ "$(hadolint --version)" != *"v2.10.0"* ]]; then
                            echo "Hadolint not found or not the desired version, installing..."
                            
                            # Download Hadolint binary
                            sudo wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.10.0/hadolint-Linux-x86_64
                            
                            # Make it executable
                            sudo chmod +x /usr/local/bin/hadolint
                        else
                            echo "Hadolint is already installed and at the correct version."
                        fi

                        # Verify installation
                        hadolint --version
                        '''
                    }
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
        stage('Lint Dockerfile') {
            when {
                expression {
                    // Check if the BRANCH_NAME is null
                    return env.BRANCH_NAME != null
                }
            }
            steps {
                script {
                    // Run Hadolint on the Dockerfile, fail the build if any issues are detected
                    sh 'hadolint Dockerfile'
                }
            }
        }
        stage('Build and push the docker image using buildx') {
            when {
                expression {
                    // Check if the BRANCH_NAME is null
                    return env.BRANCH_NAME == null
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials-id', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                    string(credentialsId: 'github-pat', variable: 'GH_TOKEN')]) {
                    script {
                        sh '''
            # Login to Docker Hub
            echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

            export GITHUB_TOKEN=$GH_TOKEN
            release_id=$(github-release list --owner $REPO_OWNER  --repo $REPO_NAME | head -n 1 | egrep -o 'id=[0-9]+' | cut -d '=' -f 2)
            release_tag=$(github-release list --owner $REPO_OWNER --repo $REPO_NAME | head -n 1 | grep -o 'tag_name="[^"]*"' | cut -d '"' -f 2 | sed 's/^v//')

            echo "The extracted release tag is: $release_tag"
            # Create and use builder instance
            # Check if the builder DOCKER_BUILDER already exists
            if ! docker buildx ls | grep -q "${DOCKER_BUILDER_NAME}"; then
                echo "Builder does not exist. Creating builder..."
                # Create the builder
                docker buildx create --name "${DOCKER_BUILDER_NAME}" --driver docker-container
            else
                echo "Builder already exists."
            fi

            # Use the builder
            docker buildx use "${DOCKER_BUILDER_NAME}"

            docker buildx ls

            # Build and push Docker image
            docker buildx build --platform linux/amd64,linux/arm64 -t ${DOCKERHUB_REPO}:${release_tag} -t ${DOCKERHUB_REPO}:${BUILD_NUMBER} --push .

            # Logout from Docker Hub
            docker logout
            '''
                    }
                }
            }
        }
        stage('Docker clean up'){
            when{
                expression{
                    return env.BRANCH_NAME == null
                }
            }
            steps{
                script{
                    sh '''
                        # Check if the builder "${BUILDER_NAME}" exists
                        if docker buildx ls | grep -q "${DOCKER_BUILDER_NAME}"; then
                            echo "Builder exists. Removing builder..."
                            docker buildx rm "${DOCKER_BUILDER_NAME}"
                        else
                            echo "Builder does not exist or already removed."
                        fi
                    '''
                }
            }
        }
        stage('Setup Commitlint') {
            when {
                expression {
                    // Check if the BRANCH_NAME is null
                    return env.BRANCH_NAME != null
                }
            }

            steps {
                sh """
        # Check if commitlint is already installed and install if not
        if ! npm list -g @commitlint/cli | grep -q '@commitlint/cli'; then
            npm install -g @commitlint/cli
        fi

        if ! npm list -g @commitlint/config-conventional | grep -q '@commitlint/config-conventional'; then
            npm install -g @commitlint/config-conventional
        fi

        # Ensure the commitlint config file is present
        if [ ! -f commitlint.config.js ]; then
            echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
        fi
        """
            }
        }
        stage('Lint commit messages') {
            when {
                expression {
                    // Check if the BRANCH_NAME is null
                    return env.BRANCH_NAME != null
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-credentials-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                node --version
                echo " source branch: $CHANGE_BRANCH"
                echo " target branch: $CHANGE_TARGET"
                echo " url: $CHANGE_URL"

                # Extract the owner and repository name from the CHANGE_URL
                OWNER=$(echo "$CHANGE_URL" | sed 's|https://github.com/\\([^/]*\\)/\\([^/]*\\)/pull/.*|\\1|')
                REPO=$(echo "$CHANGE_URL" | sed 's|https://github.com/\\([^/]*\\)/\\([^/]*\\)/pull/.*|\\2|')

                # Extract the pull request number from the CHANGE_URL
                PR_NUMBER=$(echo "$CHANGE_URL" | sed 's|.*/pull/\\([0-9]*\\).*|\\1|')

                echo "Owner: $OWNER"
                echo "Repository: $REPO"
                echo "Pull Request Number: $PR_NUMBER"

                # GitHub API endpoint to get commits from a specific pull request
                API_URL="https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/commits"

                # Make an authenticated API request to get the commits
                COMMITS=$(curl -s -H "Authorization: token $GIT_PASSWORD" "$API_URL")

                echo "$COMMITS" | jq -c '.[]' | while IFS= read -r COMMIT; do
                    # Extract the commit message from each commit JSON object
                    COMMIT_MESSAGE=$(echo "$COMMIT" | jq -r '.commit.message')


                    # Echo and lint the commit message
                    echo "Linting message: $COMMIT_MESSAGE"
                    echo "$COMMIT_MESSAGE" | npx commitlint
                    if [ $? -ne 0 ]; then
                        echo "Commit message linting failed."
                        exit 1
                    fi
                done
                '''
                }
            }
        }
    }
    post {
        success {
            echo 'Docker image or linting is sucessful pushed successfully!'
        }
        failure {
            echo 'Docker image push failed! Check the build logs for more details.'
        }
    }
}
