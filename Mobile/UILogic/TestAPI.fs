﻿module Nikeza.Mobile.UILogic.TestAPI


open Nikeza.Mobile.Profile.Try
open Nikeza.DataTransfer

let someProfile = {
    Profile.Id =        ""
    Profile.FirstName = ""
    Profile.LastName =  ""
    Profile.Email =     "test@abc.com"
    Profile.Bio =       ""
    Profile.ImageUrl =  ""
    Profile.Sources =   []
}

let someProfileRequest = {
    Nikeza.Common.ProfileRequest.Id =        ""
    Nikeza.Common.ProfileRequest.FirstName = ""
    Nikeza.Common.ProfileRequest.LastName =  ""
    Nikeza.Common.ProfileRequest.Email =     ""
    Nikeza.Common.ProfileRequest.Bio =       ""
    Nikeza.Common.ProfileRequest.ImageUrl =  ""
    Nikeza.Common.ProfileRequest.Sources =   []
}

open Nikeza.Mobile.Profile.Registration

let someValidatedForm = { 
   Form = { Email= Email ""
            Password= Password ""
            Confirm=  Password ""
          }
    }

let mockSubmit : SubmitFn =
    fun _ -> Ok someProfile

let mockFailedSubmit : SubmitFn =
    fun _ -> Error someValidatedForm

let mockSave : SaveFn =
    fun _ -> Ok someProfileRequest