﻿using System.Windows.Controls;
using Microsoft.FSharp.Core;
using Nikeza.Mobile.Profile;
using Nikeza.Mobile.UILogic.Registration;
using static Nikeza.Common;
using static Nikeza.Mobile.Profile.Registration;
using static Nikeza.Mobile.AppLogic.TestAPI;
using System.Windows;
using Nikeza.Mobile.UILogic;

namespace Desktop.App
{
    public partial class RegistrationPage : Page
    {
        ViewModel _viewmodel;

        public RegistrationPage()
        {
            InitializeComponent();

            var app = Application.Current as App;
            var shell = app.MainWindow as Shell;

            _viewmodel = shell.ViewModels().Registration;

            Password.PasswordChanged += (s, e) =>
                {
                    _viewmodel.Password = Password.Password;
                    _viewmodel.Validate.Execute(null);
                };

            Confirm.PasswordChanged += (s, e) =>
                {
                    _viewmodel.Confirm = Confirm.Password;
                    _viewmodel.Validate.Execute(null);
                };

                DataContext = _viewmodel;
        }
    }
}
