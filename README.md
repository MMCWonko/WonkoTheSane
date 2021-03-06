# WonkoTheSane

[![Gem Version](https://badge.fury.io/rb/wonko_the_sane.svg)](http://badge.fury.io/rb/wonko_the_sane)
[![Build Status](https://travis-ci.org/MMCWonko/WonkoTheSane.svg?branch=master)](https://travis-ci.org/MMCWonko/WonkoTheSane)
[![Dependency Status](https://gemnasium.com/MMCWonko/WonkoTheSane.svg)](https://gemnasium.com/MMCWonko/WonkoTheSane)
[![License](https://img.shields.io/github/license/MMCWonko/WonkoTheSane.svg)](https://img.shields.io/github/license/MMCWonko/WonkoTheSane.svg)
[![Code Climate](https://codeclimate.com/github/MMCWonko/WonkoTheSane/badges/gpa.svg)](https://codeclimate.com/github/MMCWonko/WonkoTheSane)
[![Test Coverage](https://codeclimate.com/github/MMCWonko/WonkoTheSane/badges/coverage.svg)](https://codeclimate.com/github/MMCWonko/WonkoTheSane/coverage)

From _So Long and Thanks for All the Fish_ by Douglas Adams:

> His house was certainly peculiar, and since this was the first thing that Fenchurch and Arthur had encountered it would help to know what it was like.
>
>It was like this:
>
> It was inside out.
>
> Actually inside out, to the extent that they had had to park on the carpet.
>
> All along what one would normally call the outer wall, which was decorated in a tasteful interior-deisgned pink, were bookshelves, also a couple of those odd three-legged tables with semicircular tops which stand in such a way as to suggest that someone just dropped the wall straight through them, and pictures which were clearly designed to soothe.
>
> Where it got really odd was the roof.
>
> It folded back on itself like something that M. C. Escher, had he been given to hard nights on the town, which it is no part of this narrative's purpose to suggest was the case, though it is sometimes hard, looking at his pictures, particularly the one with all the awkward steps, not to wonder, might have dreamed up after having been on one, for the little chandeliers which should have been hanging inside were on the outside pointing up.
>
> Confusing.
>
> The sign above the front door read "Come Outside," and so, nervously, they had.
>
> Inside, of course, was where the Outside was. Rough brickwork, nicely done pointing, gutters in good repair, a garden path, a couple of small trees, some rooms leading off.
>
> And the inner walls stretched down, folded curiously, and opened at the end as if, by and optical illusion which would have had M. C. Escher frowning and wondering how it was done, to enclose the Pacific Ocean itself.
>
> "Hello," said John Watson, Wonko the Sane.
>
> Good, they thought to themselves, "hello" is something we can cope with.
>
> "Hello," they said, and all, surprisingly, was smiles.
>
> ... "Your wife," said Arthur, looking around, "mentioned some toothpicks." He said it with a hunted look, as if he was worried that she might suddenly leap out from behind a door and mention them again.
>
> Wonko the Sane laughed. It was a light easy laugh, and sounded like one he had used a lot before and was happy with.
>
> "Ah yes," he said, "that's to do with the day I finally realized that the world had gone totally mad and built the Asylum to put it in, poor thing, and hoped it would get better."
>
> This was the point at which Arthur began to feel a little nervous again.
>
> "Here," said Wonko the Sane, "we are outside the Asylum." He pointed again at the rough brickwork, the pointing, and the gutters. "Go through that door" -- he pointed at the first door through which they had originally entered -- "and you go into the Asylum. I've tried to decorate it nicely to keep the inmates happy, but there's very little one can do. I never go in there myself. If I ever am tempted, which these days I rarely am, I simply look at the sign written over the door and I shy away."
>
> "That one?" said Fenchurch, pointing, rather puzzled, at a blue plaque with some instructions written on it.
>
> "Yes. They are the words that finally turned me into the hermit I have now become. It was quite sudden. I saw them, and I knew what I had to do."
>
> The sign read:
>
> "Hold stick near center of its length. Moisten pointed end in mouth. Insert in tooth space, blunt end next to gum. Use gentle in-out motion."
>
> "It seemed to me," said Wonko the Sane, "that any civilization that had so far lost its head as to need to include a set of detailed instructions for use in a package of toothpicks, was no longer a civilization in which I could live and stay sane."
>
> He gazed out at the Pacific again, as if daring it to rave and gibber at him, but it lay there calmly and played with the sandpipers.

## Wait what?

This is a ruby application that queries, fetches, sanitizes and then stores resources, currently mainly Minecraft related ones, but this can be extended.

### Why?

Having to reimplement all this hackery\^Wlogic in each client is a waste of resources, therefore this project aims at centralizing them. This means less hacks in the client (and thus the hacks can more easily be updated when needed) and overall simpler client design.

## Usage

### With docker

Install [docker](https://www.docker.com/) and run 

    $ docker run -d -v /path/to/cache:/usr/src/app/cache -v /path/to/out:/usr/src/app/out 02jandal/wonko_the_sane

This will download the `02jandal/wonko_the_sane` image and run it. Replace `/path/to/cache` and `/path/to/out` with
paths to directories on your local filesystem.

If you do not wish the container to run in the background, for example because you want to be able to view the log,
remove the `-d` option.

See the documentation for the [docker run](https://docs.docker.com/reference/run/) command for all possible options.

### Without docker

Just run

    $ gem install wonko_the_sane

And then use the `wonko_the_sane` command. Try

    $ wonko_the_sane --help

to see what you can do.

### Configuration

Several config options can be set through environment variables (use `-e NAME=VALUE` for docker):

* `WTS_AWS_CLIENT_ID`, `WTS_AWS_CLIENT_SECRET` and `WTS_AWS_BUCKET`
    * Required for uploading of backups to S3
    * The client ID/secret should have upload permissions to the bucket
* `WTS_OUT_DIR`
    * Additionally to putting all resulting files into `$PWD/files` (cannot be changed), files that are changed can
      optionally also be put into this directory. This is mainly for usage together with
      [SomebodyElsesProblem](https://github.com/MMCWonko/SomebodyElsesProblem), let `WTS_OUT_DIR` and the SEP `--indir`
      be the same.
    * If you are using the docker image this variable will already be set by the image. Do NOT overwrite it. Mount a
      volume to the container path `/usr/src/app/out` instead.

## Development

## Contributing

1. Fork it ( https://github.com/MultiMC/WonkoTheSane/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

