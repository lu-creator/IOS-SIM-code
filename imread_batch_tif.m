%从文件夹中读取多张tif图像，形成stack
function [image_stack,filename]=imread_batch_tif(pathname,start_frame)


list=dir(fullfile(pathname));
file_num=size(list,1)-2; %文件夹总文件数
file_name=strings(file_num,1);
for i=1:file_num
    file_name(i,:)=list(2+i).name;
end
[file_name_order,~] = sort_nat(file_name);


info = imfinfo((fullfile([pathname,'\',char(file_name_order(1))])));
height = info(1).Height;
width = info(1).Width;
%clear info;

% zhenshu=floor((file_num-start_frame)/9); %读取的帧数
zhenshu=floor((file_num)/9);
if height>512 ||width>512
    %截取中间512*512部分
    height_set=512;
    width_set=512;
    image_stack=zeros(height_set,width_set,zhenshu*9);
    for k=1:(zhenshu*9)
        im=imread([pathname, '\',char( file_name_order(k+start_frame-1)) ]);
        image_stack(:,:,k)=im((floor(height/2)-height_set/2):1:(floor(height/2)+height_set/2-1),...
            (floor(width/2)-width_set/2):1:(floor(width/2)+width_set/2-1));
    end

else
     image_stack=zeros(height,width,zhenshu*9);
    for k=1:(zhenshu*9)
        im=imread([pathname, '\',char( file_name_order(k+start_frame-1)) ]);
        image_stack(:,:,k)=im;
    end
end

%写出stack
filename=[list(3).name(1:end-6) ,'stack',int2str(start_frame),'.tif'];

