Name:       ru.template.Aurora_notes
Summary:    Notes App for Aurora OS
Version:    0.1
Release:    1
License:    BSD-3-Clause
URL:        https://auroraos.ru
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(auroraapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)

%description
Notes

%prep
%autosetup

%build
%qmake5
%make_build

%install
%make_install
mkdir -p %{buildroot}%{_datadir}/ru.template.Aurora_notes/translations/
cp %{_builddir}/translations/ru.template.Aurora_notes-en.qm \
   %{buildroot}%{_datadir}/ru.template.Aurora_notes/translations/
cp %{_builddir}/translations/ru.template.Aurora_notes-ru.qm \
   %{buildroot}%{_datadir}/ru.template.Aurora_notes/translations/
#cp %{_builddir}/translations/ru.template.Aurora_notes-de.qm \
#   %{buildroot}%{_datadir}/ru.template.Aurora_notes/translations/\
#cp %{_builddir}/translations/ru.template.Aurora_notes-ch.qm \
#   %{buildroot}%{_datadir}/ru.template.Aurora_notes/translations/

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%defattr(644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%{_datadir}/%{name}/translations/ru.template.Aurora_notes-en.qm
%{_datadir}/%{name}/translations/ru.template.Aurora_notes-ru.qm
#%{_datadir}/%{name}/translations/ru.template.Aurora_notes-de.qm
#%{_datadir}/%{name}/translations/ru.template.Aurora_notes-ch.qm
