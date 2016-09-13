function slicetimeindex = dicom_slicetime_index(dcmfile)
D=dicominfo(dcmfile);

st=D.Private_0019_1029;

dt=diff(sort(st));
dt=median(dt(dt>0.001));

slicetimeindex=(round(st/dt)+1);

