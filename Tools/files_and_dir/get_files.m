function [o nofiledir yesfiledir] = get_files(indir,reg_ex,p)

[o nofiledir yesfiledir] = get_subdir_regex_files(indir,reg_ex,p);

end % function
