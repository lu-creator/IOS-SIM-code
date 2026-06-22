
function imwritestacka_16(stack, filename)
	t = Tiff(filename, 'a');
    
	tagstruct.ImageLength = size(stack, 1);
	tagstruct.ImageWidth = size(stack, 2);
	tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
	tagstruct.BitsPerSample = 16;
	tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
	tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    
	for k = 1:size(stack, 3)
        img = real(stack(:, :, k));
		t.setTag(tagstruct)
		t.write(uint16(img));
		t.writeDirectory();
	end

	t.close();
end