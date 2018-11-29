# require 'file_uploader/version'
require 'httpclient'
require 'rb1drv'
require 'cloudinary'
require 'google/apis/drive_v3'

module FileUploader
  module FileUploaderInterface
    def upload(file)
      raise NotImplementedError
    end
  end

  class GoogleDriveUploader
    include FileUploaderInterface
    require 'file_uploader/google/auth'

    def upload(file)
      # Initialize the API
      service = Google::Apis::DriveV3::DriveService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize

      file_metadata = {
          name: file
      }
      file = service.create_file(file_metadata,
                                 fields: 'id',
                                 upload_source: file,
                                 content_type: 'image/jpeg')
      return 'https://drive.google.com/open?id=' + file.id
    end

    def list(limit)
      service = Google::Apis::DriveV3::DriveService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize

      # List the 10 most recently modified files.
      response = service.list_files(page_size: limit,
                                    fields: 'nextPageToken, files(id, name)')
      result = ''
      response.files.each do |file|
        result += "https://drive.google.com/open?id=#{file.id}\n"
      end

      return result
    end
  end

  class OneDriveUploader
    include FileUploaderInterface

    def upload(file)
      app_id = '510c7222-0e8a-44cf-a39f-52c7e3cc4d90'
      app_secret = 'huVBQBUB423)jgoqwP80=[_'
      callback_url = 'https://your-callback/url'

      od = OneDrive.new(app_id, app_secret, callback_url)

      return 'echo' + od.root
    end
  end

  class CloudinaryUploader
    include FileUploaderInterface

    def upload(file)
      api_key = '421836929114675'
      api_secret = 'xy111Ul88mK0iUfEO6_vPW77E5Q'
      cloud_name = 'dpbbavoeq'

      result = Cloudinary::Uploader.upload(file, api_key: api_key, api_secret: api_secret, cloud_name: cloud_name)
      return result['secure_url']
    end
  end
end