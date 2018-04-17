function [ output ] = get_subdir_regex_images(indir,reg_ex,p)

if ~exist('p'), p=struct;end

reg_ex_img = addsuffixtofilenames(reg_ex,'.*img');

if isnumeric(p)
    aa=p;clear p
    p.wanted_number_of_file = aa;
    p.verbose=0;    
end

pp.verbose=0;


output = get_subdir_regex_files(indir,reg_ex_img,pp);

if isempty(output)
    reg_ex_img = addsuffixtofilenames(reg_ex,'.*nii');
    
    output = get_subdir_regex_files(indir,reg_ex_img,pp);
    
end


%now we know the extention again to check for the number of file ask
if isfield(p,'wanted_number_of_file')
    output = get_subdir_regex_files(indir,reg_ex_img,p);
end

