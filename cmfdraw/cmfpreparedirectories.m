%%%%Script for generating subject directories and results.mat
%%%%Run preloadscript to generate cache.mat before running GUI
%%%%Or copy cache.mat from a different workspace to save time??

%%%%%%%   This script will clear any existing user-specific data!!  %%%%%%%

%Generate subject ID list cell
a2 = matchfiles('/stone/ext4/kendrick/HCP7TFIXED/??????');
subjects = cellfun(@(x) stripfile(x,1),a2,'UniformOutput',0)';
subjects = subjects(1:end-3);
subjectsUnique = subjects(randperm(numel(subjects)));

%Define user directory and save subject list
[status,userName] = unix('whoami');
userName = userName(1:end-1);
assert(~exist(strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName,'/')));
mkdir('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName);
userDir = strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName,'/');
file2save = fullfile(userDir,'subjectsUnique.mat');
save(file2save,'subjectsUnique');

%Create subjects directories
for todo = 1:181
    subject = subjects{todo};
    mkdir(userDir,subject);
end


%Fill results.mat with empty arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%xypoints: list of manually clicked points in pixel space
%xyline: pixel line from interpolation of xypoints
%vertidx: vertices corresponding to points of xyline
%vertidx_segments:
%xyNC: indices of xypoints corresponding to uncertain points
%labels: names of lines, order matters!
%xylineCell: Cell containing all line segments of a line (confident or not)
%ratings: Clarity of subject data for each hemisphere, 1:no rating, 2-4:rating
%completed: Logical of finished subject, 0:not completed, 1:finished
%currComment: Contents of subject text box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for todo = 1:181
    subjectDir = strcat(userDir,subjects{todo},'/');
    file2save = fullfile(subjectDir,'results.mat');
    xypoints = {[] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] []};
    xyline = {[] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] []};
    vertidx = {[] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] []};
    vertidx_segments = {[] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] []};
    xyNC = {[] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] []};
    labels = {'Left_V1_mid' 'Left_V1_dorsal' 'Left_V1_ventral' 'Left_V2_dorsal' 'Left_V2_ventral' 'Left_V3_dorsal' 'Left_V3_ventral' 'Left_ecc_0pt5' 'Left_ecc_1' 'Left_ecc_2' 'Left_ecc_4' 'Left_ecc_7' 'Right_mid' 'Right_V1_dorsal' 'Right_V1_ventral' 'Right_V2_dorsal' 'Right_V2_ventral' 'Right_V3_dorsal' 'Right_V3_ventral' 'Right_ecc_0pt5' 'Right_ecc_1' 'Right_ecc_2' 'Right_ecc_4' 'Right_ecc_7'};
    xylineCell = {[] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] [] []};
    ratingsRight = 1;
    ratingsLeft = 1;
    completed = 0;
    currComment = [];
    
    save(file2save,'xypoints','xyline','vertidx','vertidx_segments','labels','xylineCell','xyNC','ratingsLeft','ratingsRight','completed','currComment');
    fprintf(strcat(num2str(todo),'\n'));
end