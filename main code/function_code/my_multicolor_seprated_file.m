addpath('./util')
addpath('./TIF')
disp('Start reconstruction,please wait...');
pathname=handles.pathname;
filename=handles.filename;
filename_out= filename(1:end-4);
image_stack=handles.image_stack;

laser488=get(handles.laser488_radio,'Value');
laser561=get(handles.laser561_radio,'Value');
laser640=get(handles.laser640_radio,'Value');
color_num=laser488+laser561+laser640;

[width,height,zstack]=size(image_stack);

%% 双色情况
if color_num==2 
    % 标定文件名
      if laser488==1
          colorname1='part_488nm';
          if laser561==1&& laser640==0 
              colorname2='part_561nm';    
          elseif laser561==0 && laser640==1 
              colorname2='part_640nm';
          end
          
      elseif laser488==0 && laser561==1
          colorname1='part_561nm';
          colorname2='part_640nm';
      end
     % 划分 
      
      single_color_frame=zstack/color_num;% 每一种颜色数据的帧数
      stack_pack1=zeros(width,height,single_color_frame);
      stack_pack2=zeros(width,height,single_color_frame);
      pack=zstack/9; %36/9=4
      
      kk=0;
       for ii=1:pack    
           color_rem= rem(ii,color_num);  
           if color_rem==0 %双色时第二种
              stack_pack2(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));   
              kk=kk+1;
           elseif color_rem==1 % 第一种颜色
              stack_pack1(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
           end
       end
       
       imwritestack_16(stack_pack1,[pathname filename_out '-' colorname1 '.tif']);
       imwritestack_16(stack_pack2,[pathname filename_out '-' colorname2 '.tif']);
        
end

%% 三色情况
if color_num==3 
    % 标定文件名
       colorname1='part_488nm';
       colorname2='part_561nm';
       colorname3='part_640nm';
     % 划分 
      
      single_color_frame=zstack/color_num;% 每一种颜色数据的帧数
      stack_pack1=zeros(width,height,single_color_frame);
      stack_pack2=zeros(width,height,single_color_frame);
      stack_pack3=zeros(width,height,single_color_frame);
      pack=zstack/9; %36/9=4
      
      kk=0;
       for ii=1:pack    
           color_rem= rem(ii,color_num);  
           if color_rem==0 %三色时第三种
              stack_pack3(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));   
              kk=kk+1;
           elseif color_rem==1 % 第一种颜色
              stack_pack1(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
           elseif color_rem==2 %三色时第二种
               stack_pack2(:,:,1+kk*9:9+kk*9)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));   
           end
       end
       
       imwritestack_16(stack_pack1,[pathname filename_out '-' colorname1 '.tif']);
       imwritestack_16(stack_pack2,[pathname filename_out '-' colorname2 '.tif']);
       imwritestack_16(stack_pack3,[pathname filename_out '-' colorname3 '.tif']);
end

helpdlg('Multicolor separation have Done');
