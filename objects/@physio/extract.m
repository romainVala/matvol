function extract( physioArray )

% check if the lib is in path
assert( exist('readCMRRPhysio','file')>0 , '[%s]: "readCMRRPhysio" not detected. Download it here : https://github.com/CMRR-C2P/MB', mfilename )

% use the correct function depending on the repo version
old_version = ~isempty(which('extractCMRRPhysio'));

% get path of files
dcmfilelist = physioArray.removeEmpty().getPath();

nFile = length(dcmfilelist);
for iFile = 1 : nFile

    % prep file paths and names
    dcmfile = dcmfilelist{iFile};
    [pathstr] = fileparts(dcmfile);
    infofile = gfile(pathstr, '_Info.log$', struct('verbose',0));

    if isempty(infofile)
        fprintf('[%s]: working on %d/%d %s \n', mfilename, iFile, nFile, dcmfile)
        if old_version
            extractCMRRPhysio(char(dcmfile));
        else
            readCMRRPhysio(char(dcmfile), false, pathstr);
        end
    else
        fprintf('[%s]: skipping %d/%d because %s \n', mfilename, iFile, nFile, char(infofile))
    end

end

% auto add obj
serieArray = physioArray.removeEmpty().getSerie();
serieArray.addPhysio('Info.log$','physio_info',1)
serieArray.addPhysio('PULS.log$','physio_puls',1)
serieArray.addPhysio('RESP.log$','physio_resp',1)

end % function
