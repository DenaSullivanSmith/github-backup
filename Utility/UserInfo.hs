{- user info
 -
 - Copyright 2012 Joey Hess <joey@kitenet.net>
 -
 - Licensed under the GNU GPL version 3 or higher.
 -}

{-# LANGUAGE CPP #-}

module Utility.UserInfo (
	myHomeDir,
	myUserName,
	myUserGecos,
) where

import Control.Applicative
import System.PosixCompat

import Utility.Env

{- Current user's home directory.
 -
 - getpwent will fail on LDAP or NIS, so use HOME if set. -}
myHomeDir :: IO FilePath
myHomeDir = myVal env homeDirectory
  where
#ifndef __WINDOWS__
	env = ["HOME"]
#else
	env = ["USERPROFILE", "HOME"] -- HOME is used in Cygwin
#endif

{- Current user's user name. -}
myUserName :: IO String
myUserName = myVal env userName
  where
#ifndef __WINDOWS__
	env = ["USER", "LOGNAME"]
#else
	env = ["USERNAME", "USER", "LOGNAME"]
#endif

myUserGecos :: IO String
#ifdef __ANDROID__
myUserGecos = return "" -- userGecos crashes on Android
#else
myUserGecos = myVal [] userGecos
#endif

myVal :: [String] -> (UserEntry -> String) -> IO String
myVal envvars extract = maybe (extract <$> getpwent) return =<< check envvars
  where
	check [] = return Nothing
	check (v:vs) = maybe (check vs) (return . Just) =<< getEnv v
	getpwent = getUserEntryForID =<< getEffectiveUserID
