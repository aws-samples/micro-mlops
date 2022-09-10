#!/bin/bash

export PYTHONWARNINGS="ignore:Unverified HTTPS request"
HOOK_LOG=$HOOK_DIR/hook.log
URL=http://localhost
MLOPS_ADMIN_GROUP_ID=13
null_commit='0000000000000000000000000000000000000000'

#export GL_ID='user-1'
#export GL_PROJECT_PATH='mlops-aws/demo'
#export GL_REPOSITORY='project-2'
#export GL_USERNAME='root'

logme()
{
  timeLine=$(date "+%Y-%m-%d %H:%M:%S")
  userId=$GL_ID
  user=$GL_USERNAME
  projectPath=$GL_PROJECT_PATH
  logContent=$1
  logFile=$HOOK_LOG

  log=$( printf ' { "t":"%s", "uid":"%s", "user":"%s", "project":"%s", "log":"%s" }\n' "$timeLine" "$userId" "$GL_USERNAME" "$projectPath" "$logContent" )
  echo $log >> $logFile
}

getRole() {
  logme $GL_ID
  uid=${GL_ID#user-}
  ret=$( /usr/local/bin/gitlab -c $HOOK_DIR/.gitlab.conf -o json user-membership list --user-id=$uid | jq ".[] | select(.source_id==$MLOPS_ADMIN_GROUP_ID)" )
  if [ -z "$ret" ]; then
    echo ""
  else
    echo "ROLE_ADMIN"
  fi
}

validateBranch(){
  branchType=$1
  branch=$2

  if [[ $branchType = 'feature' ]]
  then

    str=$( echo $branch | grep -E "^${branchType}-" )
    if [ $(( ${#str} - ${#branchType} )) -gt 1 ]
    then
      echo true
    else
      echo false
    fi
  elif [[ $branchType = 'release' ]] || [[ $branchType = 'hotfix' ]]
  then

    regex="^${branchType}-([0-9]+\.){0,2}(\*|[0-9]+)$"
    str=$( echo $branch | grep -E $regex )
    if [ ${#str} -gt 0 ]
    then
      if [ "${str:0-1}" = '0' ] && [ $branchType = 'release' ]
      then
	      logme 'valid release branch'
        echo true
      elif [ "${str:0-1}" != '0' ] && [ $branchType = 'hotfix' ]
      then
	      logme 'valid hotfix branch'
        echo true
      else
	      logme 'neither a valid release/hotfix branch'
        echo false
      fi
    else
      logme 'not a valid release/hotfix branch'
      echo false
    fi
  else
    logme 'not a valid pre-defined branch'
    echo false
  fi
}

validateMerge()
{
  # 856e742 (HEAD -> main, origin/main, origin/HEAD) Merge branch 'feature-123' into 'main'
  old=$1
  new=$2

  str=$( git log --oneline $old...$new | grep ' Merge branch '  )

  if [ ${#str} -gt 0 ]
  then
    srcBranch=$( echo $str | cut -d "'" -f 2 )
    logme src-b:$srcBranch
    ret=$(validateBranch feature $srcBranch)
    if [ $ret = 'true' ]
    then
      regex="^.deploy/"
      str=$( git diff --name-only $old...$new | grep -E $regex |xargs)
      if [ ${#str} -gt 0 ]
      then
	      logme 'merge contains unexpected files'
        echo false
      else
	      logme 'ok to continue...'
        echo true
      fi
    else
      logme 'merge is NOT from a valid source feature branch'
      echo false
    fi
  else
    logme 'not a valid merge at all'
    echo false
  fi
}

validateDeploy(){
  old=$1
  new=$2
  regex="^.deploy/.(uat|prod|pre-prod).(settings)$"

  str0=$( git diff --name-only $old...$new )
  logme str0:"$str0"
  str=$( git diff --name-only $old...$new | grep -E $regex )
  n=$( git diff --name-only $old...$new | grep -E $regex | wc -l )
  t=$( git diff --name-only $old...$new | wc -l )

  logme str:"$str"
  logme n:$n
  logme t:$t
  logme code:$?

  role=$(getRole $GL_ID)
  if [ ${#role} -gt 0 ]
  then
    logme 'admin can do anything...'
    echo true
    return
  fi

  if [ $n -eq 1 ] && [ $t -eq 1 ]
  then
    env=$( echo $str | cut -d "." -f 3 )
    logme $env
    if [ $env = "prod" ]
    then
        #role=$(getRole $GL_ID)
        if [ -z "$role" ]
        then
	        logme 'non-admin is changing .prod.settings...'
          echo false
        else
          logme 'admin can do anything...'
          echo true
        fi
    else
      logme 'changing non-prod configuration...'
      echo true
    fi
  else
    logme 'uexpected changing non-deployment files...'
    echo false
  fi
}

validatePush(){
  old=$1
  new=$2

  role=$(getRole $GL_ID)
  if [ ${#role} -gt 0 ]
  then
    logme 'admin can do anything...'
    echo true
    return
  fi

  regex="^.deploy/"
  str=$( git diff --name-only $old...$new | grep -E $regex |xargs)
  logme result:$?
  if [ ${#str} -gt 0 ]
  then
    echo false
  else
    echo true
  fi
}

