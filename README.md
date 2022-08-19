# whatsapp-date

A simple bash script to set the access/modified date of whatsapp images by their filenames.

## Usage

> Filenames are strictly validated to ensure that only whatsapp images are processed.

Place your whatsapp images in a local directory and make sure they follow the format `IMG-YYYYMMDD-WAXXXX.jpg`.

The extension can be any of `jpg, jpeg, JPG, JPEG`.

```console
./whatsapp-date ./path/to/images
IMG-19990201-WA0000.jpg is before 2000-01-01! skipping ...
IMG-2018020-WA0000.jpg is invalid! skipping ...
IMG-20223112-WA1452.jpg is an invalid date! skipping ...
IMG-30000101-WA0000.jpeg is after 2099-12-31! skipping ...
Changed 7 of 11 files.
```

The output shows you which files were skipped and have not been modified.
As you can see there are some additional sanity checks to ensure integrity.

## Resources

- Regex can be found [here](https://regex101.com/r/SWfL4C/1).
- This [thread](https://unix.stackexchange.com/a/278440) was used as a starting point.

## License

[MIT](./LICENSE) License © 2022-Present [marcelhas](https://github.com/marcelhas)
