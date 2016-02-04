function cvnvisualizePRFresults(file1,file2,inputdir,pathtoresults,PRFfilename,fileout,opts,outputdir)
%cvnvisualizePRFresults(file1,file2,inputdir,pathtoresults,PRFfilename,fileout,opts,outputdir)
%
%displays PRF results in freview as surface overlays (can load up to 8
%overlays at the same time) - if the number of input variable is greater
%than 5 also takes snapshots and exits freeview - NOTE this functions is
%load overlays optimised to load independently per hemishpere
%
%if the overlays are eccentricity or polar angle the scale of the figure is
%set to be between 0 and 360, else it is scaled between 0 and 100%
%
%<file1> string variable containing the name of the inflated surface file
%to be laoded (e.g. lh.inflatedDENSETRUNCpt)
%
%<file2> string variable containing the name of the curvature to be loaded
%(e.g. lhDENSETRUNCpt)
%
%<inputdir> string variable containing the specific freesurfer subject path
%
%<pathtoresults> string containing the path where the .mat PRF results
%files are saved
%
%<PRFfilename> 1 by number of files cell string containing the name of the
%.mat PRF results file
%
%<fileout> 1 by number of files cell string containing desired path and
%name for saving the snapshots (e.g. /home/user/snapshot - optional - if
%specified saves snapshots).Note a suffix containing the Azimuth, Eelvation
%and Rotation factors will be added to the shanpshot filename
%
%<opts> optional structure containing the following fields:
%<.camzoom> variable indicating the zoom factor for the freeview camera
%(default is 1.3)
%<.Az> variable containing Azimuth factor for the freeview camera (default
%is 114 for left hemishpere and 84 for right heishpere)
%<.Ele> variable containing Elevation factor for the freeview camera
%(default is -41 for left hemishpere and -30 for right heishpere)
%<.Ro> variable containing Rotation factor for the freeview camera (default
%is -2 for left hemishpere and 8 for right heishpere). Note that the
%default values are optimized for occipita view - if a ventral view is
%desired change .Ele to -84 for the left hemisphere and to XX for the right
%hemisphere
%Note also that .Az, .Ele, and .Ro can be row or column vectors containing
%several camera angle factors. if this is the case the funcion will
%generate and save a snaphost for each value
%
%<outputdir> string contatining the path where mgz surface overlay files
%will be saves - if the directory inputted does not exist it will be
%created


flag_ss=1;
if nargin<6 && strcmp(PRFfilename{1}(1),'l')
    %occipital view
    camzoom=1.3;
    Az=114;
    Ele=-41;%-84 for ventral view
    Ro=-2;
    flag_ss=0;
elseif nargin<7 && nargin>5 && strcmp(PRFfilename{1}(1),'l')
    if ~isdir(outputdir)
        mkdir(outputdir)
    end
    camzoom=1.3;
    Az=114;
    Ele=-41;
    Ro=-2;
elseif nargin<6 && strcmp(PRFfilename{1}(1),'r')
    camzoom=1.3;
    Az=70;
    Ele=-30;
    Ro=8;
    flag_ss=0;
elseif nargin<7 && nargin>5 && strcmp(PRFfilename{1}(1),'r')
    if ~isdir(outputdir)
        mkdir(outputdir)
    end
    camzoom=1.3;
    Az=70;
    Ele=-30;
    Ro=8;
elseif nargin>6
    if ~isdir(outputdir)
        mkdir(outputdir)
    end
    camzoom=opts.camzoom;
    Az=opts.Az;
    Ele=opts.Ele;
    Ro=opts.Ro;
end

cd(inputdir)

if flag_ss==1
    for i=1:length(PRFfilename)
        for azi=1:length(Az)
            for elei=1:length(Ele)
                for roi=1:length(Ro)
                    fileout1=[outputdir,fileout{i},'_Az',num2str(Az(azi)),'_Ele',...
                        num2str(Ele(elei)),'_Ro',num2str(Ro(roi))];
                    if isempty(strfind(PRFfilename{i},'ang')) && isempty(strfind(PRFfilename{i},'ecc'))
                        cmd=sprintf(['freeview -f surf/%s:curv=surf/%s.curv:'...
                            'overlay=%s%s:overlay_method=linear:overlay_threshold=0,1,percentile'...
                            ' -cam Zoom %g Azimuth %i Elevation %i Roll %i -ss %s -colorscale'],file1,...
                            file2,pathtoresults,PRFfilename{i},camzoom,Az(azi),Ele(elei),Ro(roi),fileout1);
                    else
                        cmd=sprintf(['freeview -f surf/%s:curv=surf/%s.curv:'...
                            'overlay=%s%s:overlay_method=linear:overlay_threshold=0,360'...
                            ' -cam Zoom %g Azimuth %i Elevation %i Roll %i -ss %s -colorscale'],file1,...
                            file2,pathtoresults,PRFfilename{i},camzoom,Az(azi),Ele(elei),Ro(roi),fileout1);
                    end
                    unix(cmd)
                end
            end
        end
    end
else
    if isempty(strfind(PRFfilename{1},'ang')) && isempty(strfind(PRFfilename{1},'ecc'))
        tpe='1,percentile';
    else
        tpe='360';
    end
    for i=1:length(PRFfilename)
        cn1=length(PRFfilename{i});
        cn2=length(':overlay=');
        cn3=length(pathtoresults);
        cn4=length([':overlay_method=linear:overlay_threshold=0,',tpe]);
        cn=cn1+cn2+cn3+cn4;
        filenamePRF(1,1+(cn*(i-1)):cn+(cn*(i-1)))=[':overlay=',pathtoresults,PRFfilename{i},...
            ':overlay_method=linear:overlay_threshold=0,',tpe];
    end
    cmd=(['freeview -f surf/',file1,':curv=surf/',file2,'.curv',filenamePRF,...
        ' -cam Zoom ',num2str(camzoom),' Azimuth ',num2str(Az),' Elevation ',num2str(Ele),' Roll ',num2str(Ro)]);
    
    unix(cmd)
end

