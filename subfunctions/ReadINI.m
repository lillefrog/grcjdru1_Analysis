function values = ReadINI(fName)
% reads and INI file and returs a structure contaning all values. The
% function is quite basic and has very little error handling.
% comments start with ; or # and has to be on a seperate line not at the end of a line
% a line that starts with [ is a section head and must have a ] somewhere
% any line that is not a comment or section must be a key and contain a =

section = 'dafault'; % if there is no section name this will be used

fid = fopen(fName); % Open the file 

tline = fgetl(fid); % get the first line of text

% run trough all the lines in the file one at a time
while ischar(tline)  
    tline = strtrim(tline); % remove spaces in the biginning and end of line
    if length(tline)>1 % check that the line contains anything
        switch tline(1); % look at the first caracter in the line
            case '[' % this is a section
                pos = strfind(tline,']');
                section = tline(2:pos(1)-1);
                %disp(['section = ',tline(2:pos(1)-1)]);
            case {';','#','\','/','*'} % this is a comment
                %disp('comment');
            otherwise % this is a key
                pos = strfind(tline,'=');
                if ~isempty(pos)
                    % disp(['  key = ',tline(1:pos(1)-1), '  value = ',tline(pos(1)+1:end)]);
                    values.(section).(tline(1:pos(1)-1)) = tline(pos(1)+1:end);
                else
                    warning(['Line in INI file(',fName,') corrupted : ',tline]); %#ok<WNTAG>
                end
        end
    end
    tline = fgetl(fid); % get a new line of text
end

fclose(fid); % close file