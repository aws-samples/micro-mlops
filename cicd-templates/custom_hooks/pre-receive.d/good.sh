#!/bin/bash

HOOK_DIR=/var/opt/gitlab/gitaly/custom_hooks/pre-receive.d
. $HOOK_DIR/util.sh

while read -r oldrev newrev refname; do
    logme $oldrev
    logme $newrev
    logme $refname

    role=$( getRole $GL_ID )
    branch=${refname#refs/heads/}
    logme "ref branch is $branch"

    if [ $oldrev = $null_commit ] || [ $newrev = $null_commit ]
    then
      logme 'new branch or delete branch...'
      break
    else
      logme 'update branch...'
    fi

    if [ "${branch}" = "main" ]
    then
      logme 'target is main branch...'
    
      if [ -z "$role" ]
      then
	      ret=$(validateMerge $oldrev $newrev ${branch})
        if [ $ret = 'true' ]
        then
          logme "user is merging..."
        else
	        err_msg="push  was rejected! Non-Admin push, or the merge is not from a valid feature branch."
          break
        fi
      else
        logme 'admin can do anything...'
      fi
    elif [ $(validateBranch release $branch) = 'true' ] || [ $(validateBranch hotfix $branch) = 'true' ]
    then
      logme 'target is in release/hotfix branch...'
    
      ret=$(validateDeploy $oldrev $newrev)
      if [ $ret = 'true' ]
      then
        logme 'user is pushing into a valid release/hotfix branch'
      else
    	  err_msg="push was rejected! Shoud NOT change files except of .*.settings, or .prod.settings without an admin role "
	      break
      fi
    elif [ $(validateBranch feature $branch)  = 'true' ]
    then
      logme 'target is in feature branch...'
      ret=$(validatePush $oldrev $newrev)
      if [ $ret = 'true' ]
      then
        logme 'is pushing into target feature branch...'
      else
	      err_msg="push was rejected! Shoud NOT change deploy files in feature branche."
        break
      fi
    else
      logme 'target is not an expected feature/release/hotfix/main branch, ignored.'
    fi

    if [ $oldrev = $null_commit ] || [ $newrev = $null_commit ]
    then
      logme 'new branch or delete branch...'
    else
      logme 'update branch...'
    fi
    
done

if [ ${#err_msg} -gt 0 ]; then
    logme "$err_msg"
    logme $?
    echo GL-HOOK-ERR: "$err_msg"
    exit 1 
fi


