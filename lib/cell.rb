module Cell
	# minor version
	#   * When odd, the project is under development
	#   * When even, the project is released and will be maintained until the next even numbered release.
	# version status:
	#   * alpha - API for the current version is not set
	#   * beta - API for the current version is set, bug may exists.
	#   * rc# - Release Candidate
  #   * stable - Mostly bug free, will be maintained by point releases.
  VERSION = {
    :major => 1,
    :minor => 3,
    :micro => 0,
    :status => 'alpha',
    :string => "1.3.0-alpha"
  }

  CELL_DIR = 'app/cells'

end
