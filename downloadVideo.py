import pytube

pytube.YouTube("https://www.youtube.com/watch?v=y1xZ_kAhjMc&").streams.get_highest_resolution().download(output_path="src")