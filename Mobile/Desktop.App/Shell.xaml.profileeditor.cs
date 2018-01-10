﻿using System.Windows.Controls;
using static Nikeza.Mobile.Profile.EventExtentions.ProfileEditorEventExtension;
using static Nikeza.Mobile.Profile.EventExtentions.RegistrationSubmissionEventExtension;
using static Nikeza.Mobile.Profile.Events;
using static Desktop.App.FunctionFactory;
using ProfileEditorViewmodel = Nikeza.Mobile.UILogic.Portal.ProfileEditor.ViewModel;

namespace Desktop.App
{
    public partial class Shell
    {
        static void FromProfileEditor(Frame AppFrame, ProfileSaveEvent theEvent)
        {
            if (theEvent.IsProfileSaved)
                ToDataSources(AppFrame, theEvent.TryGetProfile().Value);

            else if (theEvent.IsProfileSaveFailed)
                ToError(AppFrame, theEvent);
        }

        static void ToProfileEditor(Frame AppFrame, RegistrationSubmissionEvent theEvent)
        {
            var portalPage = new ProfileEditorPage();
            var viewmodel = new ProfileEditorViewmodel(theEvent.TryGetProfile().Value, SaveProfile(), GetTopics());

            viewmodel.SaveEvent += (s, e) => FromProfileEditor(AppFrame, e);
            portalPage.DataContext = viewmodel;

            AppFrame.Navigate(portalPage);
        }

        static void ToError(Frame AppFrame, ProfileSaveEvent theEvent) =>
            AppFrame.Navigate(new ErrorPage());
    }
}