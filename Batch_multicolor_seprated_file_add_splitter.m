%%
pathname_superior = handles.pathname;
pathname_batch = handles.pathnameBatch;
nFile = numel(pathname_batch);

disp('Start reconstruction,please wait...');

%=============== 图像分割中心  ===========================
% 340 1024 1708
center_488=[260,1708];
center_561=[257,1024];
center_640=[257,340];
%=========================================================
    

for i_file=1:nFile
    % 导入数据
    pathename_i = pathname_batch{i_file};
    dirpath = split(pathename_i, '\');
    dirname = dirpath{end:end};
    
    disp(['Splitting:', dirname]);

    path = handles.pathname;   

    start_frame = 1;
    [image_stack,filename] = imread_batch_full_tif(pathname_batch{i_file},start_frame);
    
    [height,width,zstack] = size(image_stack); %512*2048
    
    laser488=get(handles.laser488_radio,'Value');
    laser561=get(handles.laser561_radio,'Value');
    laser640=get(handles.laser640_radio,'Value');
    color_num=laser488+laser561+laser640;
    
    % 切割后图像大小
    height_part=height-8;  %% 高度比需要的图多8，520-512
    imgx=512;
    if height < imgx
        % 如果高度小于512，则宽度为256，否则为512；
        width_part = 256;
    else
        width_part=imgx;
    end
    
    
    %% 单色情况
    if color_num==1
        % 标定文件名
        
        if laser488==1 && laser561==0 && laser640==0
            colorname1='488-part_';
            stack_pack1=image_stack(center_488(1)-height_part/2+1:1:center_488(1)+height_part/2, center_488(2)-width_part/2+1:1:center_488(2)+width_part/2,:);
        elseif laser488==0 && laser561==1 && laser640==0
            colorname1='561-part_';
            stack_pack1=image_stack(center_561(1)-height_part/2+1:1:center_561(1)+height_part/2, center_561(2)-width_part/2+1:1:center_561(2)+width_part/2,:);
        elseif laser488==0 && laser561==0 && laser640==1
            colorname1='640-part_';
            stack_pack1=image_stack(center_640(1)-height_part/2+1:1:center_640(1)+height_part/2, center_640(2)-width_part/2+1:1:center_640(2)+width_part/2,:);
            
        end
        imwritestack(stack_pack1,[path '\' colorname1 dirname '.tif']);
        
    end
    
    if color_num==2
        % 图像分时
        single_color_frame=zstack/color_num;% 每一种颜色数据的帧数
        stack_pack_temp1=zeros(height,width,single_color_frame);
        stack_pack_temp2=zeros(height,width,single_color_frame);
        pack=zstack/9; %36/9=4
        
        kk=0;
        for ii=1:pack
            color_rem= rem(ii,color_num);
            if color_rem==0 %双色时第二种
                stack_pack_temp2(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
                kk=kk+1;
            elseif color_rem==1 % 第一种颜色
                stack_pack_temp1(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
            end
        end
        
        
        % 标定文件名+位置切割
        stack_pack1=zeros(height_part,width_part,zstack);
        stack_pack2=zeros(height_part,width_part,zstack);
        if laser488==1
            colorname1='488-part_';
            stack_pack1=stack_pack_temp1(center_488(1)-height_part/2+1:1:center_488(1)+height_part/2, center_488(2)-width_part/2+1:1:center_488(2)+width_part/2,:);
            if laser561==1&& laser640==0
                colorname2='561-part_';
                stack_pack2=stack_pack_temp2(center_561(1)-height_part/2+1:1:center_561(1)+height_part/2, center_561(2)-width_part/2+1:1:center_561(2)+width_part/2,:);
            elseif laser561==0 && laser640==1
                colorname2='640-part_';
                stack_pack2=stack_pack_temp2(center_640(1)-height_part/2+1:1:center_640(1)+height_part/2, center_640(2)-width_part/2+1:1:center_640(2)+width_part/2,:);
            end
            
        elseif laser488==0 && laser561==1
            colorname1='561-part_';
            colorname2='640-part_';
            stack_pack1=stack_pack_temp1(center_561(1)-height_part/2+1:1:center_561(1)+height_part/2, center_561(2)-width_part/2+1:1:center_561(2)+width_part/2,:);
            stack_pack2=stack_pack_temp2(center_640(1)-height_part/2+1:1:center_640(1)+height_part/2, center_640(2)-width_part/2+1:1:center_640(2)+width_part/2,:);
        end
        
        imwritestack(stack_pack1, [path '\' colorname1 dirname '.tif']);
        imwritestack(stack_pack2, [path '\' colorname2 dirname '.tif']);
        
        
        
        
    end
    
    %% 三色情况
    if color_num==3
        % 标定文件名
        colorname1='488-part_';
        colorname2='561-part_';
        colorname3='640-part_';
        % 图像分时
        single_color_frame=zstack/color_num;% 每一种颜色数据的帧数
        stack_pack_temp1=zeros(height,width,single_color_frame);
        stack_pack_temp2=zeros(height,width,single_color_frame);
        stack_pack_temp3=zeros(height,width,single_color_frame);
        pack=zstack/9; %36/9=4
        
        kk=0;
        for ii=1:pack
            color_rem= rem(ii,color_num);
            if color_rem==0 %三色时第三种
                stack_pack_temp3(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
                kk=kk+1;
            elseif color_rem==1 % 第一种颜色
                stack_pack_temp1(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
            elseif color_rem==2 %三色时第二种
                stack_pack_temp2(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
            end
        end
        
        
        % 位置划分
        %stack_pack1=zeros(512,512,zstack);
        %stack_pack2=zeros(512,512,zstack);
        %stack_pack3=zeros(512,512,zstack);
        
        stack_pack1=stack_pack_temp1(center_488(1)-height_part/2+1:1:center_488(1)+height_part/2, center_488(2)-width_part/2+1:1:center_488(2)+width_part/2,:);
        stack_pack2=stack_pack_temp2(center_561(1)-height_part/2+1:1:center_561(1)+height_part/2, center_561(2)-width_part/2+1:1:center_561(2)+width_part/2,:);
        stack_pack3=stack_pack_temp3(center_640(1)-height_part/2+1:1:center_640(1)+height_part/2, center_640(2)-width_part/2+1:1:center_640(2)+width_part/2,:);
        
        imwritestack(stack_pack1, [path '\' colorname1 dirname '.tif']);
        imwritestack(stack_pack2, [path '\' colorname2 dirname '.tif']);
        imwritestack(stack_pack3, [path '\' colorname1 dirname '.tif']);
    end
    
    
    disp(['Finished:', pathename_i]);
    clear stack_pack1 stack_pack2 stack_pack3
end



disp('All Done');
helpdlg('All Done');
