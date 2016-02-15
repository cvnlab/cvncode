function [vertices, faces, tagblock] = freesurfer_read_surf(fname,varargin)

% freesurfer_read_surf - FreeSurfer I/O function to read a surface file
% 
% [vertices, faces] = freesurfer_read_surf(fname,'param',value,...)
% 
% Reads the vertex coordinates (mm) and face lists from a surface file.
% 
% Surface files are stored as either triangulations or quadrangulations.
% That is, for a triangulation, each face is defined by 3 vertices.  For a
% quadrangulation, each face is defined by 4 vertices.  The rows of 'faces'
% contain indices into the rows of 'vertices', the latter holds the XYZ
% coordinates of each vertex.
%
% The freesurfer faces index the vertices in counter-clockwise order (when
% viewed from the outside of the surface).  This is consistent with a
% right-hand rule.  If we have vertices
%
% C           B
%
%
%       A
%
% Then we can calculate an edge vector from A to B (ie, AB = B - A) and
% another edge vector from A to C (ie, AC = C - A).  If you form a "gun"
% with your thumb and forefinger of the right hand, then align your thumb
% with the AB vector and your forefinger with the AC vector, your palm is
% facing out of the screen and extending your middle finger in the
% orthogonal direction to the plane of the screen will give the outward
% surface normal of the triangle ABC.  (If you lookup "triangle" on
% Wolfram's mathworld, you can see that AB is referred to as c and AC is
% referred to as b.)
%
% However, if this surface is read into matlab, it will give INWARD surface
% normals in the matlab patch command.  For some reason, matlab is not
% following the right hand rule.  To get OUTWARD normals with the matlab
% patch command, use faces(:,[1 3 2]) (see below).
%
% The vertex coordinates are in mm.  The FreeSurfer coordinate
% system for surfaces is quite simple, but relating to their MRI
% cor-??? files is too confusing to explain here; see the FreeSurfer
% homepage or google the documentation by Graham Wideman.  For the
% surfaces, at least, the origin is somewhere in the center of the
% head, and the vertex XYZ coordinates are oriented such that +X is
% right, +Y is anterior and +Z is superior (this is the
% FreeSurfer RAS coordinate system).
%
% Note that reading the faces of a quad file can take a long
% time due to their compact storage format.  In this case, the return of
% vertices can be faster if the face output variable is not specified; in
% this case, the faces are not read.
% 
% Try this to visualize the surface:
% Hp = patch('vertices',vertices,'faces',faces(:,[1 3 2]),...
%       'facecolor',[.5 .5 .5],'edgecolor','none')
% camlight('headlight','infinite')
% vertnormals = get(Hp,'vertexnormals');
%
% See also freesurfer_write_surf, freesurfer_read_curv,
%          freesurfer_read_wfile
%
%
% Modified by KJ:
% 1. Return an optional third value containing the "tag block" at the end
% of the surface file.  This tag block can be passed to
% freesurfer_write_surf_kj(v,f,tagblock) to maintain freesurfer's
% positioning information.
% 2. Added optional argument 'justcount', which returns just the vertex and
% face count for a surface file (Much faster if this is all you need):
%   [Nverts,Nfaces]=freesurfer_read_surf_kj(filename,'justcount',true);

% $Revision: 1.2 $ $Date: 2011/02/07 21:47:40 $

% Copyright (C) 2000  Darren L. Weber

% History:  08/2000, Darren.Weber_at_radiology.ucsf.edu
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%
%default options
options=struct(...
    'justcount',false,...
    'verbose',false);

%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%parse options
input_opts=mergestruct(varargin{:});
fn=fieldnames(input_opts);
for f = 1:numel(fn)
    opt=input_opts.(fn{f});
    if(~(isnumeric(opt) && isempty(opt)))
        options.(fn{f})=input_opts.(fn{f});
    end
end
%%%%%%%%%%%%%%%%%%%%


verbose = options.verbose;
ver = '$Revision: 1.2 $ $Date: 2011/02/07 21:47:40 $';

if(verbose)
    printfcn = @fprintf;
else
    printfcn = @(varargin)([]);
end

printfcn('FREESURFER_READ_SURF [v %s]\n',ver(11:15));

if(nargin < 1)
    help freesurfer_read_surf_kj;
    return;
end

%QUAD_FILE_MAGIC_NUMBER =  (-1 & 0x00ffffff) ;
%NEW_QUAD_FILE_MAGIC_NUMBER =  (-3 & 0x00ffffff) ;

TRIANGLE_FILE_MAGIC_NUMBER  =  16777214;
QUAD_FILE_MAGIC_NUMBER      =  16777215;


% open it as a big-endian file
fid = fopen(fname, 'rb', 'b');
if (fid < 0),
    str = sprintf('could not open surface file %s.', fname);
    error(str);
end

printfcn('...reading surface file: %s\n', fname);
tic;

magic = freesurfer_fread3(fid);

if (magic == QUAD_FILE_MAGIC_NUMBER),
    Nvertices = freesurfer_fread3(fid);
    Nfaces = freesurfer_fread3(fid);
    if(options.justcount)
        vertices=Nvertices;
        faces=Nfaces;
        fclose(fid);
        return;
    end
    printfcn('...reading %d quad file vertices\n',Nvertices);
    vertices = fread(fid, Nvertices*3, 'int16') ./ 100 ; 
    if (nargout > 1),
        printfcn('...reading %d quad file faces (please wait)\n',Nfaces);
        faces = zeros(Nfaces,4);
        for iface = 1:Nfaces,
            for n=1:4,
                faces(iface,n) = freesurfer_fread3(fid) ;
            end
            if(~rem(iface, 10000)), printfcn(' %7.0f',iface); end
            if(~rem(iface,100000)), printfcn('\n'); end
        end
    end
elseif (magic == TRIANGLE_FILE_MAGIC_NUMBER),
    printfcn('...reading triangle file\n');
    tline = fgets(fid); % read creation date text line
    tline = fgets(fid); % read info text line
    
    Nvertices = fread(fid, 1, 'int32'); % number of vertices
    Nfaces = fread(fid, 1, 'int32'); % number of faces
    
    if(options.justcount)
        vertices=Nvertices;
        faces=Nfaces;
        fclose(fid);
        return;
    end
    % vertices are read in column format and reshaped below
    vertices = fread(fid, Nvertices*3, 'float32');
    
    % faces are read in column format and reshaped
    faces = fread(fid, Nfaces*3, 'int32');
else
    str = sprintf('unknown magic number in surface file %s.', fname);
    error(str);
end

tagblock = char(fread(fid,'uchar'));
fclose(fid);

vertices = reshape(vertices, 3, Nvertices)';
faces = reshape(faces, 3, Nfaces)';
printfcn('...adding 1 to face indices for matlab compatibility.\n');
faces = faces + 1;

t=toc; printfcn('...done (%6.2f sec)\n\n',t);

return

